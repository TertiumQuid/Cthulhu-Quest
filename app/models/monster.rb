class Monster < ActiveRecord::Base
  has_many :threats
  has_many :combats
  has_many :denizens
  has_many :locations, :through => :denizens
  
  KIND = ['human','entity','creature','animal','spirit']
  
  validates :name, :length => { :minimum => 1, :maximum => 256 }  
  validates :kind, :presence => true, :inclusion => { :in => KIND }  
  
  def sanity_resistence_for(investigator)
    investigator.combats.where(:monster_id => id).successes.count
  end
end