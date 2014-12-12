class MagicSet < ActiveRecord::Base
  belongs_to :magic_block
  has_many :magic_cards

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def to_param
    code
  end

end

#Attributes
#name | string
#code | string
#magic_block_id | integer
