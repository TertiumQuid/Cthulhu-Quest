class Grimoire < ActiveRecord::Base
  has_and_belongs_to_many :spells

  validates :name, :presence => true
end