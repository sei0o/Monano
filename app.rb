require 'sinatra/base'
#require 'sinatra/reloader'
require 'active_record'
require './monacoinrpc.rb'
require './autodraw.rb'

class Monano < Sinatra::Base

	@@wallet = MonacoinRPC.new('http://monacoinrpc:EJ6aJgxqFgUMsE2oQPMrzmXHC3BRXfzaLNXJeURiUkSg@127.0.0.1:10010')

	configure do
		Sinatra::Application.reset!
		use Rack::Reloader
		set :site_name, "Monano"
		set :price, 0.001
	end

	use ActiveRecord::ConnectionAdapters::ConnectionManagement

	ActiveRecord::Base.establish_connection(
		adapter: "sqlite3",
		database: "data/database.db"
	)

	class Pack < ActiveRecord::Base; end
	class Ticket < ActiveRecord::Base; end

	get '/' do
		@title = "#{settings.site_name}へようこそ"
		
		@packs = Pack.all
		
		erb :index
	end
	
	post '/buy' do
		amount  = params[:amount].to_i
		address = params[:address]
		
		halt "正しいアドレスを指定せよ" unless @@wallet.validateaddress(address)["isvalid"]
		
		pack = Pack.create(amount: amount,
										   nyuukin_address: @@wallet.getnewaddress, # 振込先アドレス
										   payout_address: address,
										   paid: 0.0, paid_confirmed: 0.0, payouted: 0)
		# ラベルを貼っておく
		@@wallet.setaccount pack.nyuukin_address, pack.id
		
		amount.times do
			Ticket.create pack_id: pack.id
		end
		
		puts "Pack Created: #{pack.id}:#{pack.payout_address}:: #{@@wallet.getaccount pack.payout_address}"
		
		redirect "/pack/#{pack.id}"
	end
	
	get '/pack/*' do |id|
		
		@pack = Pack.find id
		@pay_complete = true
		
		# 入金確認  
		if @pack.paid < @pack.amount * settings.price
			@pay_complete = false
			@pack.paid           = @@wallet.getreceivedbyaddress @pack.nyuukin_address, 0
			@pack.paid_confirmed = @@wallet.getreceivedbyaddress @pack.nyuukin_address, 6
		end
	
		@pack.save
		
		@title = "パック詳細"
		erb :pack
	end
	
end