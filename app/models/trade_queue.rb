class TradeQueue < ActiveRecord::Base
  has_one :magic_account
  has_one :user, through: :magic_account
  has_one :transfer
  has_one :runner, class_name: 'Bot', foreign_key: 'runner_id'
  has_one :bank, class_name: 'Bot', foreign_key: 'bank_id'
  
  validates_presence_of :status
  validates_presence_of :magic_account_id


end

#Attributes
#magic_account_id | integer
#runner_id | integer
#bank_id | integer
#status | string
#type | string
#cancelled | boolean
#transfer_id | integer
#history | text