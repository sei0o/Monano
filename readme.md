Monano
======

Sinatra &amp; Monacoinで宝くじの練習

How to Run
--------
1. install gems
```
$ gem install sinatra activerecord
```

2. clone repo & Run!
```
$ git clone https://github.com/sei0o/Monano.git  
$ cd Monano  
$ rackup  
```

Edit config.yml
----------
`site_name`: Site name. default is `Monano`.  
`ticket_price`: price(Mona) per one ticket.  
`draw_time`: draw time. example: `2014-12-7-11-30-11`  
`last_draw`: last drawed time. do not change.  
`check_interval`: draw time check interval. (see `autodraw.rb`)  
`host`: described on `monacoin.conf`.    
`user`: described on `mon`(ry  
`password`: describ(ry  
`port`: de(ry)  
`wallet_passphrase`: monacoin wallet's passphrase. use for payout.  
`wallet_account`: Account for Monano.  
`address_prefix`: prefix for generated address's account.   
`winners`: list of winners count.  example:  
```
- 1 # 1st rank. 1 winner.
- 1 # 2nd rank. 1 winner.
- 3 # 3rd rank. 3 winners.
- 5 # 4th rank. 5 winners.
...
```
`payout_percentage`: percentage of payout. example:
``` YAML
- 0.3 # payout of 1st rank. 30% of ALL received money.
- 0.2 # payout of 2nd rank. 20% of ALL received money.
- 0.1 # payout of 3th rank. 10% of ALL received money.
- 0.03 # payout of 4th rank. 3% of ALL received money.
...
```
