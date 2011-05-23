class Possession < ActiveRecord::Base
  ORIGIN = ['purchase','gift','reward']
  
  belongs_to :item
  belongs_to :investigator 
  
  attr_accessor :origin
  
  scope :items, joins("JOIN items ON items.id = possessions.item_id")
  scope :inventory, where("items.kind = 'equipment' OR items.kind = 'medical' OR items.kind = 'artifact' OR items.kind = 'spirit'")
  scope :books, where("items.kind = 'book'")
  scope :medical, where("items.kind = 'medical'")  
  scope :spirit, where("items.kind = 'spirit'")    
  scope :artifacts, where("items.kind = 'artifact'")  
                                                   
  before_validation :set_item_name, :on => :create
  before_validation :set_uses_count, :on => :create
  after_create      :log_purchase
  
  validates :investigator_id, :presence => true, :numericality => true
  validates :item_id, :presence => true, :numericality => true
  validates :item_name, :presence => true  
  validates :origin, :allow_blank => true, :inclusion => { :in => ORIGIN }
  validate  :origin_valid, :on => :create
  validate  :uniqueness_valid, :on => :create
  
  def use!(investigator=nil)
    return unless usable?
    return study_book if item.book?
    return unless cooldown_valid?
    
    if uses_count > 1
      self.last_used_at = Time.now
      update_attribute(:uses_count, uses_count - 1)
    else
      destroy
    end
    use_medicine(investigator) if item.medical?
    use_spirit(investigator) if item.spirit?
    create_effects
    true
  end
  
  def usable?
    !uses_count.blank?
  end
  
  def used?
    usable? && uses_count < 1
  end
  
  def targeting_self?(target)
    target.blank? || target.id == investigator_id
  end
  
  def studyable?
    last_used_at.blank? || cooldown_finished?( Item::STUDY_TIMEFRAME )
  end
  
  def remaining_study_time_in_percent
    100 - (((Time.now - last_used_at) / ((last_used_at + Item::STUDY_TIMEFRAME.hours) - last_used_at)) * 100).round
  end  
  
  def primed?
    last_used_at.blank? || (item.activatable? && cooldown_finished?( Item::ACTIVATION_TIMEFRAME ) )
  end
  
  def cooldown_finished?(timeframe)
    last_used_at.blank? || last_used_at < (Time.now - timeframe.hours)
  end
  
private

  def origin_valid
    return if origin.blank? || !purchase?
    errors[:investigator_id] << "lacking funds" unless valid_purchase?
  end
  
  def uniqueness_valid
    return unless new_record? && item && item.book?
    errors[:item_id] << "already possessed" if investigator.possessions.where(:item_id => item_id).exists?
  end
  
  def cooldown_valid?
    return true unless item && item.activatable? && !cooldown_finished?( Item::ACTIVATION_TIMEFRAME )
    errors[:base] << "still recharging from last use"
    return false
  end
  
  def purchase?
    origin == 'purchase'
  end
  
  def valid_purchase?
    item && investigator && investigator.funds >= item.price
  end
  
  def set_uses_count
    self.uses_count = item.uses_count if item
  end

  def set_item_name
    self.item_name = item.name if item
  end
  
  def study_book
    if !studyable?
      errors[:base] << "you are still studying this book right now"
    elsif uses_count < 1
      errors[:base] << "you have already studied this book in full"
    else
      investigator.update_attribute(:moxie, investigator.moxie + 1)
      self.uses_count = uses_count - 1
      self.last_used_at = Time.now
      return save
    end 
    false
  end
  
  def use_medicine(target=nil)
    return unless item.medical?
    
    targets = [investigator]
    targets << target unless targeting_self?(target)
    wounds_recovered = item.power + investigator.healing_effect_bonus
    
    targets.each do |t|
      t.update_attribute(:wounds, [t.wounds - wounds_recovered, 0].max)
    end
    log_medical_treatment(target)
  end
  
  def use_spirit(target=nil)
    return unless item.spirit?
    
    targets = [investigator]
    targets << target unless targeting_self?(target)
    madness_recovered = item.power
    
    targets.each do |t|
      t.update_attribute(:madness, [t.madness - madness_recovered, 0].max)
    end
    log_spirit_drunken(target)
  end
  
  def log_medical_treatment(target=nil)
    InvestigatorActivity.log investigator, 'wounds.self.healing'
    
    unless targeting_self?(target)
      InvestigatorActivity.log investigator, 'wounds.ally.healing', :actor => target
      InvestigatorActivity.log target, 'wounds.received.healing', :actor => investigator
    end
  end  
  
  def log_spirit_drunken(target=nil)
  end
  
  def create_effects
    return unless item.activatable?
    
    item.effects.each do |effect|
      effect.effections.create(:investigator => investigator)
    end
  end  
  
  def log_purchase
    return unless purchase?
    
    InvestigatorActivity.log investigator, 'item.purchased', :subject => item
  end
end