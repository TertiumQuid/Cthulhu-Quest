class Assignment < ActiveRecord::Base
  STATUS = ['requested','accepted','refused','unanswered']
  RESULT = ['succeeded','failed']

  belongs_to :intrigue
  belongs_to :investigation
  belongs_to :investigator
  belongs_to :contact
  belongs_to :ally, :class_name => 'Investigator'
  has_one    :combat
  
  before_validation :set_status
  before_validation :set_investigator, :on => :create
  after_create      :log_investigator_assignment
  after_create      :send_facebook_app_request
  
  validates :investigator_id, :numericality => true
  validates :intrigue_id, :numericality => true
  validates :ally_id, :numericality => true, :allow_blank => true
  validates :contact_id, :numericality => true, :allow_blank => true
  validates :status, :inclusion => { :in => STATUS }
  validates :result, :allow_blank => true, :inclusion => { :in => RESULT }
  
  validate  :status_updated, :on => :update
  validate  :challenge_matched, :on => :create
  validate  :association_authentication, :on => :create
  validate  :favors_available, :on => :create
    
  scope :requested, where(:status => 'requested')
  scope :successful, where(:result => 'succeeded')  
  scope :favorable, where('contact_id IS NOT NULL')
  scope :join_investigation, joins("JOIN investigations ON investigations.id = investigation_id")
  scope :join_plot_thread, joins("JOIN plot_threads ON plot_threads.id = investigations.plot_thread_id")
  scope :investigating, where("investigations.status = 'active' OR investigations.status = 'investigated'")
  scope :investigation, includes(:investigation)
  
  def investigate!
    combat_threat!
    self.challenge_target = success_target
    self.challenge_score = random
    
    success = challenge_target > 0 && (challenge_score <= challenge_target)
    self.result = (success ? 'succeeded' : 'failed')
    save
    remove_facebook_app_request
    return success
  end
  
  def fail!
    self.challenge_target = 0
    self.challenge_score = Intrigue::CHALLENGE_RANGE
    self.result = 'failed'
    save
    remove_facebook_app_request
  end
  
  def respond!(response)
    self.status = response.is_a?(Hash) ? response[:status] : response
    log_investigator_response
    remove_facebook_app_request
    save
  end
  
  def combat_threat!
    return unless threat = intrigue.threat
    threat.combat!( self )
  end
    
  def is_assignable?(assignable)
    !assignable.blank? && assignable.send( challenge_name ) > 0
  end
  
  def assignable(assignables)
    assignable = []
    (assignables || []).each do |a|
      assignable << a if is_assignable?( a )
    end
    return assignable
  end

  def self_assigned?
    ally_id.blank? && contact_id.blank?
  end
  
  def ally_assigned?
    !ally_id.blank?
  end
  
  def contact_assigned?
    !contact_id.blank?
  end  

  def requested?
    status == 'requested'
  end
  
  def accepted?
    status == 'accepted'
  end
  
  def refused?
    status == 'refused'
  end  
  
  def successful?
    result == 'succeeded'
  end
  
  def challenge_name
    intrigue.challenge.name.downcase
  end
  
  def helpers(options={})
    return "You #{options[:past] ? 'faced' : 'face'} this intrigue alone." if self_assigned?
    ally_name = options[:html] ? "<strong>#{ally.name}</strong>" : ally.name if ally_id
    contact_name = options[:html] ? "<strong>#{contact.name}</strong>" : contact.name if contact_id
    
    helpers = if accepted? && ally_id && contact_id
      if options[:past]
        "#{ally_name} and #{contact_name} helped you with this intrigue."
      else
        "#{ally_name} and #{contact_name} are helping you with this intrigue."
      end
    elsif accepted? && ally_id
      if options[:past]
        "#{ally_name} helped you with this intrigue."
      else
        "#{ally_name} is helping you with this intrigue."
      end
    elsif contact_id    
      if options[:past]
        "#{contact_name} helped you with this intrigue."
      else
        "#{contact_name} is helping you with this intrigue."
      end
    else
      "You #{options[:past] ? 'faced' : 'face'} this intrigue alone."
    end
    return helpers
  end
  
private

  def random
    rand( Intrigue::CHALLENGE_RANGE ) 
  end

  def success_target
    threshold = intrigue.threshold( investigator, 
                                    (ally_id && accepted? ? ally : nil),
                                    (contact_id ? contact.character : nil) 
    )
    threshold = threshold + investigation.consecutive_failure_bonus
    return threshold
  end
  
  def status_updated
    if status_changed? && !(status_was == 'requested')
      errors[:status] << "can no longer be updated"
    end
  end
  
  def challenge_matched
    return if intrigue_id.blank?
    
    if contact && !is_assignable?( contact.character )
      errors[:contact_id] << "does not have expertise to meet challenge"
    end
    
    if ally && !is_assignable?( ally )
      errors[:ally_id] << "does not have expertise to meet challenge"
    end    
  end

  def set_status
    self.status ||= (ally_assigned? ? 'requested' : 'accepted')
  end
    
  def set_investigator
    self.investigator_id ||= investigation.investigator.id if investigation
  end
  
  def association_authentication
    return unless investigator
    unless ally_id.blank? || investigator.inner_circle_ids.include?(ally_id)
      errors[:ally_id] << "is not among your inner circle"
    end
    
    unless contact_id.blank? || investigator.contact_ids.include?(contact_id)
      errors[:contact_id] << "is not known to you"
    end    
  end
  
  def favors_available
    return unless new_record? && contact
    errors[:contact_id] << "owes you no favors" if contact.favor_count < 1
  end
  
  def log_investigator_assignment
    return unless ally_assigned?
    InvestigatorActivity.log ally, 'investigation.assigned', :actor => investigator, :subject => investigation.plot_thread
  end
  
  def log_investigator_response
    return unless ally_assigned?
    InvestigatorActivity.log investigator, "assignment.#{status}", :actor => ally, :subject => intrigue
    InvestigatorActivity.log ally, "assignment.assigned", :actor => investigator, :subject => intrigue if accepted?
  end
  
  def send_facebook_app_request
    return unless Rails.env.production? && ally_assigned? && ally.user
    message = "#{ally.user.name} requires your help to #{intrigue.title}"
    self.facebook_request_id = (ally.user.send_app_request(message, id) rescue nil)
    save && facebook_request_id
  end
  
  def remove_facebook_app_request
    return unless Rails.env.production? && ally_assigned? && ally.user && facebook_request_id
    ally.user.remove_app_request(facebook_request_id) rescue nil
    update_attribute(:facebook_request_id, nil)
  end
end