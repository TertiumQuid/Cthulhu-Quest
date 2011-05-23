class Item < ActiveRecord::Base
  KIND = ['equipment','book','medical','artifact','spirit']
  STUDY_TIMEFRAME = 18
  ACTIVATION_TIMEFRAME = 12
  
  has_many :prerequisites, :as => :requirement, :dependent => :destroy
  has_many :possessions, :dependent => :destroy
  has_many :effects, :as => 'trigger'
  
  scope :dry_goods, where("items.price > 0 AND kind IN ('equipment','medical','spirit')")
  scope :artifacts, where("kind IN ('artifact')") 
  scope :purchasable, where("items.price > 0 AND kind IN ('equipment','medical','artifact','spirit')")
  scope :personal,  where("items.price = 0") 
  scope :medical, where(:kind => 'medical')
  scope :spirit, where(:kind => 'spirit')
      
  validates :kind, :inclusion => { :in => KIND }
  
  def activatable?
    kind == 'artifact'
  end
  
  def medical?
    kind == 'medical'
  end  
  
  def book?
    kind == 'book'
  end
  
  def spirit?
    kind == 'spirit'
  end  
  
  def equipment?
    kind == 'equipment'
  end  
  
  def effect_names
    effects.map(&:name).join(', ')
  end
end