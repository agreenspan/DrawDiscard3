class Transaction < ActiveRecord::Base
  belongs_to :buyer, class_name: 'User', foreign_key: 'buyer_id'
  belongs_to :seller, class_name: 'User', foreign_key: 'seller_id'
  belongs_to :magic_card
  belongs_to :stock

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0.01 }
  validates_presence_of :status
  validates_presence_of :magic_card_id
  validate :has_buyer_or_seller?
  if ["selling", "finished"].include? :status
    validates_presence_of :stock_id
  end

  private

    def has_buyer_or_seller?
      if buyer_id.blank? && seller_id.blank?
      	return false
      else
      	return true
      end
    end

end

#Attributes
#buyer_id | integer
#seller_id | integer
#stock_id | integer
#magic_card_id | integer
#price | decimal
#start | datetime
#finish | datetime
#status | string


