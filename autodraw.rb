require 'active_record'
require 'yaml'
require './monacoinrpc.rb'

ActiveRecord::Base.establish_connection(
	adapter: "sqlite3",
	database: "data/database.db"
)

config = YAML.load_file "config.yml"
wallet = MonacoinRPC.new "http://#{config["user"]}:#{config["password"]}@#{config["host"]}:#{config["port"]}"

class Pack < ActiveRecord::Base; end
class Ticket < ActiveRecord::Base; end

draw_time = Time.new *(config["draw_time"].split("-"))
last_draw = Time.new *(config["last_draw"].split("-"))
winner_count = config["winners"]
payout_percentage = config["payout_percentage"] # 残りは手数料として胴元に

# 抽選時刻になるまで監視(別スレッドで同時進行)
t1 = Thread.start do
	loop do
		# 現在時刻が抽選時刻を過ぎている
		if draw_time <= Time.now # 現在時刻とぴったりとは限らない
			break if last_draw == draw_time # もう抽選した
			
			sold = Ticket.count
			
			# 抽選!
			winners = []
			
			winner_count.each_with_index do |wincount, rank| # 等級全て
				winners[rank] = []
				wincount.times do # n等の当選者分
					win_id = rand(sold) + 1 # 乱数で当選チケットIDを決定
					ticket = Ticket.find win_id
					pack   = Pack.find ticket.pack_id
					
					print pack.paid
					
					if pack.amount * config["ticket_price"] <= pack.paid # 入金済みなら
						winners[rank] << win_id
						puts " win!"
					else
						puts " redored"
						redo # 生成し直し
					end
				end
			end
			
			# Monano用accountにまとめておく(支払い準備)
			Pack.count.times do |i|
				paid_account = "#{config["address_prefix"]}#{i+1}"
				balance = wallet.getbalance paid_account
				puts "balance ", balance, paid_account
				# 入金されたアドレスから全額移動(balanceが0以下だとerror)
				wallet.move paid_account, config["wallet_account"], balance if balance > 0
			end
			
			# 支払い
			
			paid_all = 0 # 売上総金額を求める
			Pack.all.each do |pack|
				if pack.amount * config["ticket_price"] <= pack.paid # 入金済みなら
					paid_all += pack.paid
				end # 中途半端な入金は没収
			end
			
			puts "---------DRAWED!----------------------"
			
			payouts = {}
			winners.each_with_index do |rank_winners, rank|
				payout = paid_all * payout_percentage[rank] # rankで当選金額は一緒
			
				print "#{rank+1}等(#{payout}Mona): "
				
				rank_winners.each do |rank_winner|
					ticket = Ticket.find rank_winner
					pack = Pack.find ticket.pack_id
					# けたを8けたにしておいてから支払い
					payouts[pack.payout_address] = ("%.8f" % payout).to_f
					pack.payouted = ("%.8f" % payout).to_f # DB更新
					pack.save
					print "#{rank_winner} "
				end
				
				puts ""
			end
			
			# まとめて支払い
			wallet.walletpassphrase config["wallet_passphrase"], 3
			wallet.sendmany config["wallet_account"], payouts
			
			puts "---------------------------------------"
			puts "All paid: #{paid_all} Mona"
			puts "Wallet: #{wallet.getbalance config["wallet_account"]} Mona"
			puts "---------------------------------------"
			
			# 最終抽選を更新
			config["last_draw"] = config["draw_time"]
			File.open "config.yml", "w" do |file|
				YAML.dump config, file
			end
			
			break # loopを抜ける
		end
		
		sleep config["check_interval"]
	end
end

#t1.join