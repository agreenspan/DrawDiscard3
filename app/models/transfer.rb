class Transfer < ActiveRecord::Base
  belongs_to :magic_account
  belongs_to :user
  has_many :trade_queues
  has_many :stocks
  
  validates_presence_of :user_id
  validates_presence_of :magic_account_id


end

#Attributes
#user_id | integer
#magic_account_id | integer
#wallet_depositing | integer
#wallet_withdrawing | integer