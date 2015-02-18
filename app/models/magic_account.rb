class MagicAccount < ActiveRecord::Base
  belongs_to :user
  has_many :stocks, dependent: :destroy
  has_many :transfers
  has_many :trade_queues

  VALID_NAME_REGEX = /\A[\w\-.]+\z/
  validates :name, presence: true, format: { with: VALID_NAME_REGEX }

  before_destroy :not_in_queue?

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

end

#Attributes
#name | string
#user_id | integer
