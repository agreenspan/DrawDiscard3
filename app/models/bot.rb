class Bot < ActiveRecord::Base
  has_many :stocks
  has_many :users
  has_many :runner_for,  class_name: 'TradeQueue', foreign_key: 'runner_id'
  has_many :bank_for,  class_name: 'TradeQueue', foreign_key: 'bank_id'

  VALID_NAME_REGEX = /\A[\w\-.]+\z/
  validates :name, presence: true, uniqueness: true, format: { with: VALID_NAME_REGEX }
  validates :role, presence: true

  def trade_queues
  	if self.type == "runner"
  		return self.runner_for
  	elsif self.type == "bank" 
        return self.bank_for
  	end
  end

end

#Attributes
#name | string
#role | string
#wallet | integer