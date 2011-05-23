require 'action_view/helpers/date_helper'

class Investigation < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  
  STATUS = ['active','investigated','completed','unsolved','solved']
  
  belongs_to :plot_thread, :counter_cache => true
  has_many :assignments, :dependent => :destroy

  scope :solved,       where("investigations.status = 'solved'")
  scope :unsolved,     where("investigations.status = 'unsolved'")
  scope :completed,    where("investigations.status = 'completed'")  
  scope :investigated, where("investigations.status = 'investigated'")    
  scope :active,       where("investigations.status = 'active'") do
    def elapse(id)
      investigation = find_by_id(id)
      investigation.elapse! if investigation && investigation.elapsed?
      investigation
    end
    
    def elapse_all
      investigations = all
      unless investigations.blank?
        investigations.select{ |i| i.elapsed? }.each { |i| i.elapse! }
        investigations = investigations.select{ |i| i.active? }
      end
      investigations
    end
  end
  scope :open,        where("investigations.status <> 'solved' AND investigations.status <>'unsolved'").limit(1)
  scope :ready,       where("investigations.status = 'investigated' OR investigations.status = 'completed'")
  scope :assignments, includes(:assignments => [:intrigue,:ally,:contact])
  
  accepts_nested_attributes_for :assignments
  
  before_validation :set_moxie,            :on => :create
  before_validation :set_status,           :on => :create
  before_validation :set_plot_title,       :on => :create
  after_validation  :set_duration,         :on => :create
  after_save        :use_items,            :on => :create
  after_save        :update_plot_thread,   :on => :create
  before_create     :build_successful_assignments
  after_create      :speedy_investigation
  after_create      :use_favors
  after_create      :log_investigation

  validates :plot_thread_id, :numericality => true  
  validates :moxie_speed, :numericality => true  
  validates :moxie_challenge, :numericality => true
  validates :plot_title, :length => { :minimum => 1, :maximum => 64 }
  validates :status, :inclusion => { :in => STATUS }
  validates_associated :assignments
  validate  :validates_concurrency,         :on => :create
  validate  :validates_assignments,         :on => :create
  validate  :validates_ally_exclusivity,    :on => :create
  validate  :validates_contact_exclusivity, :on => :create
  validate  :validates_availability,        :on => :create
  validate  :validates_prerequisites,       :on => :create
  validate  :validates_moxie
  
  def advance_state!(solution_id=nil)
    if active? && elapsed?
      elapse!
    elsif investigated?
      complete!
    elsif completed?
      solve!(solution_id)
    end
  end
  
  def elapse!
    update_attribute(:status, 'investigated') if active?
  end
  
  def complete!
    unless investigated?
      errors[:base] << "cannot be completed yet"
      return false
    end
    
    update_attribute(:finished_at, Time.now)
    if do_intrigue_challenges == true
      update_attribute(:status, 'completed')
      set_unanswered_assignments
      return true
    else
      update_attribute(:status, 'unsolved')
      plot_thread.update_attribute(:status, 'available')
      set_unanswered_assignments
      log_failure
      return false
    end
  end
  
  def solve!(solution_or_id)
    if !completed?
      errors[:base] << "cannot currently be solved"
      return false
    elsif solution_or_id.blank?
      errors[:base] << "solution cannot be blank"
      return false
    end
    solution = solution_or_id.is_a?(Integer) ? plot.solutions.find(solution_or_id) : solution_or_id
    
    update_attribute(:status, 'solved') 
    plot_thread.solution_id = solution.id
    plot_thread.status = 'solved'
    plot_thread.save
    log_success
    reward_investigators
    award_madness
    return true
  end
  
  def hasten!(moxie=nil)
    return true if remaining_hours < 1
    if remaining_hours > investigator.moxie
      errors[:moxie_speed] << "not enough moxie to finish your investigation"
      return false
    else  
      elapse!
      investigator.update_attribute(:moxie, investigator.moxie - moxie_speed)
      return true
    end
  end
  
  def completed?
    status == 'completed'
  end

  def investigated?
    status == 'investigated'
  end
  
  def solved?
    status == 'solved'
  end  
  
  def unsolved?
    status == 'unsolved'
  end
      
  def active?
    status == 'active'
  end
      
  def elapsed?
    ((Time.now - created_at) / 1.hour).floor.abs >= duration
  end
  
  def investigation_ends_at_in_words
    unless active? || investigated?
      ended = (created_at + plot.duration.hours)
      return distance_of_time_in_words( Time.now, ended ) + ' ago'
    end
    
    ends = created_at + duration.hours
    return distance_of_time_in_words(Time.now, ends)
  end
  
  def remaining_hours
    return 0 unless active? && !elapsed?
    time_until = (created_at + duration.hours) - Time.now 
    hours,minutes,seconds,frac = Date.day_fraction_to_time( time_until )
    return (hours.to_f / 100000).ceil
  end
  
  def build_assignments
    return unless assignments.blank? && plot
    intrigues = plot.intrigues.challenge.threat.all
    successful_assignments = plot_thread.assignments.successful

    intrigues.each do |intrigue|
      a = if (successful = successful_assignments.select{|a| a.intrigue_id == intrigue.id }.first)
        assignments.build :intrigue => intrigue, 
                          :result => 'succeeded', 
                          :challenge_target => successful.challenge_target, 
                          :challenge_score => successful.challenge_score
      else
        assignments.build :intrigue => intrigue
      end
      a.investigation = self
    end
  end 
  
  def remaining_time_in_percent
    100 - (((Time.now - created_at) / ((created_at + duration.hours) - created_at)) * 100).round
  end  
  
  def set_assignment_owner
    assignments.each do |a|
      a.investigation = self
    end   
  end
    
  def plot
    plot_thread && plot_thread.plot
  end
  
  def investigator
    plot_thread && plot_thread.investigator
  end  
  
  def consecutive_failure_bonus
    return 0 if investigator.blank?
    
    failures = investigator.investigations
    failures = failures.unsolved
    failures = failures.where(:plot_thread_id => plot_thread_id)
    return failures.count
  end
    
private

  def build_successful_assignments
    successful_assignments = plot_thread.assignments.successful
    
    assignments.each do |assignment| 
      if (successful = successful_assignments.select{|a| a.intrigue_id == assignment.intrigue_id }.first)
        assignment.result = 'succeeded'
        assignment.challenge_target = successful.challenge_target
        assignment.challenge_score = successful.challenge_score
      end      
    end
  end

  def do_intrigue_challenges
    success = true
    assignments.select{|a| !a.successful? }.each do |assignment| 
      if success
        assignment.investigate!
      else
        assignment.fail!
      end
      success = success && assignment.successful?
    end  
    success
  end
  
  def validates_availability
    return unless new_record? && plot_thread

    unless plot_thread.available?
      errors[:base] << "unavailable for investigation"
    end    
    
  end

  def validates_concurrency
    return unless new_record? && investigator
    
    if investigator.investigations.active.exists?
      errors[:base] << "already preoccupied with other investigations"
    end    
  end
  
  def validates_assignments
    return unless new_record? && plot

    if assignments.size != plot.intrigues.size
      errors[:base] << "must assign an investigator to every intrigue"
    else
      ids = plot.intrigue_ids
      assignments.each do |a|
        errors[:base] << "intrigue does not match plot" unless ids.include?( a.intrigue_id )
      end
    end    
  end
  
  def validates_ally_exclusivity
    ids = []
    assignments.select{ |a| !a.ally_id.blank? }.each do |a|
      if ids.include?( a.ally_id )
        errors[:base] << "ally cannot be assigned to multiple intrigues"
      end
      ids << a.ally_id
    end
  end
  
  def validates_contact_exclusivity
    ids = []
    assignments.select{ |a| !a.contact_id.blank? }.each do |c|
      if ids.include?( c.contact_id )
        errors[:base] << "contact cannot be assigned to multiple intrigues"
      end
      ids << c.contact_id
    end
  end  
  
  def validates_prerequisites
    Prerequisite.validate_investigation(self) if plot && new_record?
  end
  
  def validates_moxie
    if investigator.blank?
      return
    elsif new_record?
      errors[:moxie_speed] << "not enough moxie to assign" if investigator.moxie < moxie_speed
    else
      errors[:moxie_speed] << "not enough moxie to assign" if moxie_speed_changed? && investigator.moxie < (moxie_speed - moxie_speed_was)
      errors[:moxie_challenge] << "not enough moxie to assign" if moxie_challenge_changed? && investigator.moxie < (moxie_challenge - moxie_challenge_was)
    end
  end

  def set_moxie
    self.moxie_challenge = 0
    self.moxie_speed ||= 0
  end

  def set_status
    self.status = 'active'
  end  
  
  def set_plot_title
    self.plot_title = plot_thread.plot_title if plot_thread
  end
  
  def set_duration
    self.duration = plot_thread && plot_thread.plot ? plot_thread.plot.duration : 0
  end
  
  def speedy_investigation
    hasten! if moxie_speed >= duration
  end
  
  def update_plot_thread
    plot_thread.update_attribute(:status, 'investigating') unless new_record?
  end
  
  def use_items
    plot_thread.use_items!
  end
  
  def use_favors
    assignments.favorable.each do |f|
      f.contact.use_favor!
    end
  end
  
  def reward_investigators
    plot_thread.reward_investigator! # reward investigator
    
    exp = 1
    assignments.each do |assignment|
      next unless assignment.ally_assigned? && assignment.accepted?
      assignment.ally.award_experience!(exp) # reward ally
      InvestigatorActivity.log assignment.ally, 'assignment.reward', :actor => assignment.investigator, :object => assignment.intrigue, :scope => exp
    end
  end
  
  def award_madness
    investigator.award_madness!(plot.madness) if investigator && plot
  end
  
  def set_unanswered_assignments
    assignments.each do |assignment|
      assignment.update_attribute(:status, 'unanswered') if assignment.requested?
    end
  end
  
  def log_investigation
    InvestigatorActivity.log investigator, 'plot.investigating', :subject => plot_thread
  end
  
  def log_failure
    InvestigatorActivity.log investigator, 'plot.failed', :subject => plot_thread
  end
  
  def log_success
    InvestigatorActivity.log investigator, 'plot.solved', :subject => plot_thread
  end  
end