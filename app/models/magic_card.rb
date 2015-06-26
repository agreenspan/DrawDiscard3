class MagicCard < ActiveRecord::Base
  belongs_to :magic_set
  has_many :stocks
  has_many :transactions


  validate :mtgo_id, presence: true, uniqueness: true
  validates_presence_of :name
  validates_presence_of :magic_set_id
  validates_presence_of :object_type
  if :object_type == "card"
    validates_presence_of :rarity
  end
  if ["card","planar","vanguard"].include?(:object_type)
    validates_presence_of :collector_number
  end
  before_create :generate_plain_name

  def to_params
    mtgo_id
  end

  def generate_plain_name
    self.plain_name = name.downcase.replace_special_characters
  end

end

#Attributes
#mtgo_id | integer
#object_type | string
#name | string
#plain_name | string
#magic_set_id | integer
#rarity | string
#foil | boolean
#collector_number | string
#art_version | string
#disabled | boolean


