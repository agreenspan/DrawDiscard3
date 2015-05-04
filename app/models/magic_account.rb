class MagicAccount < ActiveRecord::Base
  belongs_to :user
  has_many :stocks, dependent: :destroy
  has_many :trade_queues

  VALID_NAME_REGEX = /\A[\w\-.]+\z/
  validates :name, presence: true, format: { with: VALID_NAME_REGEX }

  before_destroy :not_in_queue?
  before_destroy :revert_withdrawing

  def in_queue?
  	if self.trade_queues.where.not(status: "finished").any?
  	  return true
  	else
  	  return false
  	end
  end

  def not_in_queue?
    return !in_queue?
  end

  def revert_withdrawing
    stocks_left = true 
    while 
      stocks_left = false
      Stock.where(magic_account_id: self.id, status: "withdrawing").each do |stock|
        stock.with_lock do 
          if stock.status == "withdrawing"
            stock.update_attributes(status: "online", magic_account_id: "")
          else
            stocks_left = true
          end
        end
      end
    end
    self.user.update_attribute(:wallet, self.user.wallet + self.tickets_withdrawing)
    self.update_attribute(:tickets_withdrawing, 0)
  end

end

#Attributes
#name | string
#user_id | integer
#tickets_depositing
#tickets_withdrawing