class Denizen < ActiveRecord::Base
  belongs_to :monster
  belongs_to :location
  
  scope :monster, includes(:monster)
end