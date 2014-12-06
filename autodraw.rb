require 'active_record'

ActiveRecord::Base.establish_connection(
	adapter: "sqlite3",
	database: "data/database.db"
)

class Pack < ActiveRecord::Base; end
class Ticket < ActiveRecord::Base; end

draw_time = Time.new 2014, 11, 25, 23, 5
winner_count = [1, 1, 3, 5]
payout_percentage = [0.3, 0.2, 0.1, 0.03] # 残りは手数料として胴元に

# 抽選時刻になるまで監視
#loop do
	puts Time.now
	#if draw_time <= Time.now # ぴったりとは限らない
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
				
				if pack.amount * 0.001 <= pack.paid # 入金済みなら
					winners[rank] << win_id
					puts " win!"
				else
					#redo # 生成し直し
					puts " redored"
				end
			end
		end
		
		puts "---------DRAWED!----------------------"
		winners.each_with_index do |rank_winners, rank|
			print "#{rank+1}等: "
			rank_winners.each do |rank_winner|
				print "#{rank_winner} "
			end
			puts ""
		end
		puts "--------------------------------------"
		
		# 支払い
		payouts = []
		
		paid = 0 # 売上総金額を求める
		Pack.all.each do |pack| 
			pack.paid * 0.001
		end
		
		#break # loopを抜ける
	#end
	
	sleep 2
#end