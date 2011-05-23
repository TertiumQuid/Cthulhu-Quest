class Social < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  
  belongs_to :investigator
  belongs_to :social_function
  has_many   :guests, :dependent => :destroy
  
  before_validation :set_name
  before_validation :set_appointment_at, :on => :create  
  before_create     :set_logs
  after_create      :log_social
  
  serialize :logs

  validates :investigator_id, :numericality => true  
  validates :social_function_id, :numericality => true  
  validates :name, :length => { :minimum => 1, :maximum => 128 }
  validates :appointment_at, :presence => true
  validate  :validates_no_active_social, :on => :create
  
  scope :for_allies, lambda {|ally_ids| where("socials.investigator_id IN (?)", ally_ids)}
  scope :planning, lambda {|| where("created_at > ? AND appointment_at < ?", Time.now, Time.now)}
  scope :scheduled, lambda {|| where("appointment_at < ?", Time.now)}
  scope :active, where(:hosted_at => nil)
  scope :hosted, where("hosted_at IS NOT NULL")  
  scope :guests, includes(:guests => :investigator)
  scope :inviting, lambda { |investigator_id| 
    joins("LEFT JOIN guests ON guests.social_id = socials.id AND guests.investigator_id = #{investigator_id.to_i}").where("guests.investigator_id IS NULL")
  }
  
  def host!
    self.logs = default_logs
    if hosted?
      errors[:base] << "already hosted"
    elsif !scheduled?
      errors[:base] << "is not yet scheduled"
    else
      update_attribute(:hosted_at, Time.now)
      reward_guests
      reward_host
      log_hosted
    end
    return errors[:base].empty? && save
  end
  
  def hosted?
    !hosted_at.blank?
  end
  
  def scheduled?
    !appointment_at.blank? && appointment_at <= Time.now && !hosted?
  end
  
  def scheduled_at_in_words
    if hosted?
      ended = (created_at + SocialFunction::TIMEFRAME.hours)
      return distance_of_time_in_words( Time.now, ended ) + ' ago'
    elsif scheduled?  
      return 'ready'
    end
    
    ends = created_at + SocialFunction::TIMEFRAME.hours
    return distance_of_time_in_words(Time.now, ends)
  end  
  
  def remaining_time_in_percent
    100 - (((Time.now - created_at) / ((created_at + SocialFunction::TIMEFRAME.hours) - created_at)) * 100).round
  end  
  
  def percent_complete
    100 - remaining_time_in_percent
  end
  
private

  def default_logs
    {:host_reward => nil, :guest_rewards => []}
  end

  def validates_no_active_social
    if investigator && investigator.socials.active.exists?
      errors[:base] << "You are already hosting another active social function."
    end
  end

  def set_name
    self.name = social_function.name if name.blank? && social_function
  end  

  def set_appointment_at
    self.appointment_at ||= (Time.now + SocialFunction::TIMEFRAME.hours)
  end
  
  def set_logs
    self.logs ||= {}
  end
  
  def reward_host
    score = (defector_count > 1) ? 1 : 2
    msg = social_function.reward_investigator( investigator, score )
    logs[:host_reward] = host_message( msg )
  end
  
  def host_message(msg)
    "As the host of the #{social_function.name}, #{investigator.name} #{msg}"
  end
  
  def reward_guests
    defectors = defector_count
    
    guests.each do |d| 
      msg = reward_guest(d, defectors) 
      behavior = d.cooperated? ? 'an amiable' : 'an atrocious'
      log_guest_reward d.investigator, guest_message( d.investigator, behavior, msg )
    end
  end
  
  def reward_guest(guest, defectors)
    desc = social_function.reward_investigator( guest.investigator, guest_score(guest, defectors) )
    guest.update_attribute(:reward, desc)
    desc
  end
  
  def guest_message(guest, behavior, message)
    "#{guest.name} was #{behavior} guest at #{investigator.name}'s #{social_function.name} and #{message}"
  end
  
  def defector_count
    effect_bonus > 0 ? 0 : guests.defecting.count
  end
    
  def guest_score(guest, defectors)
    if defectors == 0
      2
    elsif defectors > 1
      0
    elsif defectors == 1 && (guest.defected?)
      3
    elsif defectors == 1 && !(guest.defected?)
      1
    end
  end
  
  def effect_bonus
    investigator.effections.active.effect.bonding.sum("effects.power").to_i
  end  
  
  def log_guest_reward(guest, msg)
    logs[:guest_rewards] << msg
    InvestigatorActivity.log guest, 'social.function', :subject => self, :actor => investigator, :message => msg
  end
  
  def log_social
    InvestigatorActivity.log investigator, 'social.function', :object => social_function
  end
  
  def log_hosted  
    InvestigatorActivity.log investigator, 'social.hosted', :object => social_function
  end  
end