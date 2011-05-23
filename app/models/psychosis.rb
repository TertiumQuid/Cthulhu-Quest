class Psychosis < ActiveRecord::Base
  TREATMENT_RANGE = 10 
  
  belongs_to :insanity
  belongs_to :investigator, :counter_cache => true
  
  validates :insanity_id, :numericality => true  
  validates :investigator_id, :numericality => true  
  
  scope :insanity, includes(:insanity)
  scope :treating, where("next_treatment_at IS NOT NULL")
  scope :treatable, lambda {|| where(["next_treatment_at < ?", Time.now])}
    
  before_validation :set_name, :on => :create  
  after_create      :log_insanity
  after_destroy     :log_treatment
  
  class << self  
    def insanities_for(investigator)
      return [] if investigator.blank?
      ids = investigator.psychoses.where("severity < 3").map(&:insanity_id)
      ids.blank? ? Insanity.scoped : Insanity.where(["id NOT IN (?)", ids ])
    end
    
    def award!(investigator)
      insanities = insanities_for(investigator)
      return false if insanities.blank?
      
      insanity = insanities[ rand(insanities.size) ]
      psychosis = investigator.psychoses.find_or_initialize_by_insanity_id(:insanity_id => insanity.id)
      psychosis.severity = psychosis.severity+1 unless psychosis.new_record?
      psychosis.save
    end
  end
  
  def begin_treatment!
    if investigator.psychoses.treating.exists?
      errors[:base] << "already in treatment for a different insanity"
      return false
    end
    update_attribute(:next_treatment_at, Time.now + treatment_hours)    
  end
  
  def finish_treatment!
    unless treatable?
      errors[:base] << "must spend more time institutionalized before finishing treatment"
      return false
    end
    
    if random > treatment_threshold
      if severity > 1
        update_attribute(:severity, severity - 1)
        update_attribute(:next_treatment_at, nil)
      else
        destroy        
      end
      return true
    else
      update_attribute(:next_treatment_at, nil)
      treatment_failed
      return false
    end
  end
  
  def treating?
    !next_treatment_at.blank?
  end
  
  def treatable?
    treating? && next_treatment_at <= Time.now
  end  
  
  def treatment_hours
    (severity * 9).hours
  end
  
  def treatment_threshold
    (severity * 3)
  end  
  
  def degree
    case severity
      when 1
        'Mild'
      when 2
        'Aggrevated'
      when 3
        'Severe'
    end
  end
  
  def remaining_time_in_percent
    return 100 unless treating?
    100 - (((Time.now - (next_treatment_at - treatment_hours)) / (next_treatment_at - (next_treatment_at - treatment_hours))) * 100).round
  end  
  
private

  def random
    rand( TREATMENT_RANGE ) 
  end  
  
  def treatment_failed
    investigator.award_madness!(severity)
  end
  
  def set_name
    self.name = insanity.name if insanity
  end  
  
  def log_insanity
    InvestigatorActivity.log investigator, 'insanity.gained', :subject => insanity
  end
  
  def log_treatment
    InvestigatorActivity.log investigator, 'insanity.treated', :subject => insanity
  end  
end