class Contact < ActiveRecord::Base
  belongs_to :character
  belongs_to :investigator
  
  before_validation :set_name, :on => :create  

  validates :character_id, :numericality => true
  validates :investigator_id, :numericality => true  
  validates :favor_count, :numericality => true
  validates :name, :length => { :minimum => 1, :maximum => 128 }
  
  scope :favorable, where('favor_count > 0')
  scope :character, includes(:character => [:character_skills,:location])
  scope :located_at, lambda { |location_id|
    joins("JOIN characters ON character_id = characters.id").where(["characters.location_id = ?", location_id])
  }
    
  def use_favor!
    return false if favor_count < 1
    update_attribute(:favor_count, favor_count - 1)
  end
  
  def entreat_favor!
    return false unless entreatable? && located?
    self.favor_count = favor_count + 1
    self.last_entreated_at = Time.now
    log_entreat
    save
  end
  
  def located?
    character.location_id == investigator.location_id
  end
  
  def entreatable?
    last_entreated_at.nil? || last_entreated_at < (Time.now - 1.day)
  end
  
  def percent_before_entreatable
    entreatable? ? 100 : (((Time.now - last_entreated_at) / ((last_entreated_at + 24.hours) - last_entreated_at)) * 100).round
  end  
  
private

  def set_favor_count
    self.favor_count ||= 0
  end

  def set_name
    self.name ||= character.name if character
  end  
  
  def log_entreat
    InvestigatorActivity.log investigator, 'contact.entreat', :subject => character
  end
end