class Weapon < ActiveRecord::Base
  KIND = ['firearm','blade']

  scope :dry_goods, where("weapons.price > 0")
  
  validates :kind, :presence => true, :inclusion => { :in => KIND }  
end