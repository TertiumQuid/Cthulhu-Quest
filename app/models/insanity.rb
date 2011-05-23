class Insanity < ActiveRecord::Base
  has_many :psychoses
  belongs_to :skill
end