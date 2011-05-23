class Ally < ActiveRecord::Base
  MAX_ALLIES = 9
  
  belongs_to :investigator
  belongs_to :ally, :class_name => 'Investigator'
  
  validates :investigator_id, :numericality => true  
  validates :ally_id, :numericality => true, :uniqueness => {:scope => :investigator_id}
  validates :name, :length => { :minimum => 1, :maximum => 128 }
  validate  :cannot_ally_oneself
  
  before_validation :set_name, :on => :create
  after_create      :log_alliance

  scope :without_contact_for, lambda { |character_id| 
    where("ally_id NOT IN (SELECT investigator_id FROM contacts WHERE character_id = #{character_id.to_i})")
  }  
  scope :need_introduction_for, lambda { |character_id| 
    where("ally_id NOT IN (SELECT investigator_id FROM introductions WHERE character_id = #{character_id.to_i})")
  }
  scope :investigator, includes(:investigator).where("investigator_id IS NOT NULL")
  scope :ally, includes(:ally => [:user,:positive_stats])
  
private

  def cannot_ally_oneself
    errors[:ally_id] << "cannot be self" if investigator_id && investigator_id == ally_id
  end
  
  def set_name
    self.name = ally.name if new_record? && ally
  end  
  
  def log_alliance
    InvestigatorActivity.log investigator, 'ally.added', :actor => ally
    InvestigatorActivity.log ally, 'ally.allied', :actor => investigator
  end
end