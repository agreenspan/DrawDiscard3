class User < ActiveRecord::Base
  has_secure_password
  has_many :magic_accounts
  has_many :trades, through: :magic_accounts
  has_many :stocks
  has_many :bids, class_name: "Transaction", foreign_key: "buyer_id"
  has_many :listings, class_name: "Transaction", foreign_key: "seller_id"
  has_many :transfers
  belongs_to :bank, class_name: 'Bot', foreign_key: "bot_id"

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8, maximum: 255 }

  before_save { self.email = email.downcase }
  after_create :assign_bank

  def in_queue?
  	if self.trades.where.not(status: "finished").any?
  	  return true
  	else
  	  return false
  	end
  end

  def not_in_queue?
    return !in_queue?
  end

  def generate_confirmation_code
    self.update_attribute(:confirmation_code, SecureRandom.urlsafe_base64.to_s)
  end

  private

    def assign_bank
      self.update_attribute(:bot_id, Bot.where(role: "bank").sample.id)
    end

end

#Attributes
#email | string
#password_digest | string
#confirmation_code | string
#confirmed | boolean
#user_code | string
#bot_code | string
#account_status | string
#wallet | integer