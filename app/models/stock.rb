class Stock < ActiveRecord::Base
  belongs_to :user
  belongs_to :magic_account
  belongs_to :bot
  belongs_to :magic_card
  belongs_to :transfer
  has_many :transactions

  before_destroy :check_status_before_destroy
  validates_presence_of :magic_card_id
  validates_presence_of :status
  validates_presence_of :user_id
  validate :bot_or_magic_account?

  private

    def check_status_before_destroy
      if !["depositing", "offline"].include?(self.status) 
        raise CustomExepction.new("Stock cannot be deleted while in this state.")
      end
    end

    def bot_or_magic_account?
      if bot_id.blank? && magic_account_id.blank? #&& status != "ghost"
        raise CustomExepction.new("Stock must be on a bank bot or a magic account.")
        return false
      else
        return true
      end
    end

end

#Attributes
#user_id | integer
#magic_account_id | integer
#bot_id | integer
#magic_card_id | integer
#status | string
#transfer_id | integer
