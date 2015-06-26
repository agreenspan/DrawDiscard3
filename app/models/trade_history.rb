class TradeHistory < ActiveRecord::Base
  belongs_to :trade_queue
  belongs_to :bot

end

#Attributes
#trade_queue_id | integer
#bot_id | integer
#status | string
