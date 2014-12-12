class MagicBlock < ActiveRecord::Base
  has_many :magic_sets

  validates :name, presence: true, uniqueness: true

end

#Attributes
#name | string