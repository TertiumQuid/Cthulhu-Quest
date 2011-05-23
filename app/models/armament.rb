class Armament < ActiveRecord::Base
  ORIGIN = ['purchase','gift','reward']
  
  belongs_to :weapon
  belongs_to :investigator
  
  scope :weapons, includes(:weapon)
  
  before_validation :set_weapon_name, :on => :create
  after_create      :arm_investigator
  
  attr_accessor :origin
  
  validates :investigator_id, :numericality => true
  validates :weapon_id, :numericality => true, :uniqueness => {:scope => :investigator_id}  
  validates :weapon_name, :presence => true  
  validates :origin, :allow_blank => true, :inclusion => { :in => ORIGIN }
  validate  :origin_valid, :on => :create
  
private

  def origin_valid
    return if origin.blank? || !purchase?
    errors[:investigator_id] << "lacking funds" unless valid_purchase?
  end
  
  def purchase?
    origin == 'purchase'
  end
    
  def valid_purchase?
    weapon && investigator && investigator.funds >= weapon.price
  end

  def set_weapon_name
    self.weapon_name = weapon.name if weapon
  end
  
  def arm_investigator
    investigator.update_attribute(:armed_id, id) if investigator.armed_id.nil?
  end
end