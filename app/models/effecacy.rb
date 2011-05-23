class Effecacy < ActiveRecord::Base
  has_many :effects, :dependent => :destroy
  has_many :effections, :through => :effects
end