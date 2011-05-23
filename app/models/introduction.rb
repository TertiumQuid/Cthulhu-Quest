class Introduction < ActiveRecord::Base
  STATUS = ['arranged','accepted','dismissed']
  TIMEFRAME = 24
  COST = 2
    
  belongs_to :investigator
  belongs_to :character
  belongs_to :introducer, :class_name => 'Investigator'
  belongs_to :plot
  
  before_validation :set_status, :on => :create
  after_validation  :set_message, :on => :create
  after_validation  :use_favors, :on => :create  
  after_create      :log_introduction
  
  scope :arranged, where("status = 'arranged'")
  
  validates :investigator_id, :numericality => true
  validates :character_id, :numericality => true
  validates :status, :inclusion => { :in => STATUS }  
  validate  :validates_introducer_or_plot, :on => :create
  validate  :validates_no_contact, :on => :create
  validate  :validates_introducer_favors, :on => :create
  validate  :validates_introducer_location, :on => :create
  validate  :validates_one_introduction_per_day, :on => :create  
  
  def accept!
    if !arranged?
      errors[:base] << "introduction not arranged"
      return false
    elsif !located?
      errors[:base] << "investigator must be at character's location"
      return false      
    end
    update_attribute(:status, 'accepted')
    reward_introducer
    reward_investigator
    true
  end
  
  def dismiss!
    return unless arranged?
    update_attribute(:status, 'dismissed')
    punish_introducer
  end
  
  def located?
    investigator && character && investigator.location_id == character.location_id
  end

  def introduced?
    !introducer_id.blank?
  end
  
  def arranged?
    status == 'arranged'
  end
  
private

  def reward_investigator
    investigator.contacts.create(:character_id => character_id)
  end

  def reward_introducer
    return unless introduced?
    introducer.award_experience!( Introduction::COST )
  end
  
  def punish_introducer
    return unless introduced?
    contact = introducer.contacts.find_by_character_id( character_id )
    contact.update_attribute(:favor_count, 0)
  end

  def validates_no_contact
    errors[:investigator_id] << "already has contact" if investigator && investigator.contacts.where(:character_id => character_id).exists?
  end

  def validates_introducer_or_plot
    if introducer.blank? && plot.blank?
      errors[:base] << "must be acquired through an investigator or plot"
    end
  end
  
  def validates_one_introduction_per_day
    if introducer && !introducer.can_introduce?
      errors[:introducer_id] << "has already arranged one introduction today"
    end
  end

  def validates_introducer_favors
    return unless introducer && character_id
    contact = introducer.contacts.where(:character_id => character_id).first
    errors[:character_id] << "does not have enough favors" if contact.favor_count < Introduction::COST
  end
  
  def validates_introducer_location
    return unless introducer && character
    errors[:introducer_id] << "cannot arrange an introduction unless in character location" if introducer.location_id != character.location_id
  end
  
  def set_message
    self.message = if introducer && character
      "#{introducer.name} has arranged for your introduction to #{character.name}"
    elsif plot && character
      "in the course of solving #{plot.title}, you earned an introduction to #{character.name}"
    end
  end
  
  def set_status
    self.status = 'arranged' if new_record?
  end  
  
  def use_favors
    return unless introducer
    contact = introducer.contacts.where(:character_id => character_id).first
    contact.update_attribute(:favor_count, [contact.favor_count - Introduction::COST, 0].max)
  end
  
  def log_introduction
    return unless introduced?
    InvestigatorActivity.log introducer, 'contact.introduced', :actor => investigator, :subject => character
    InvestigatorActivity.log investigator, 'contact.introduction', :actor => introducer, :subject => character
  end
end