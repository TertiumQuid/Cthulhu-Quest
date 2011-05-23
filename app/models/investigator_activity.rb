class InvestigatorActivity < ActiveRecord::Base
  belongs_to :activity
  belongs_to :investigator
  belongs_to :actor, :polymorphic => true
  belongs_to :object, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  
  validates :activity_id, :numericality => true  
  validates :investigator_id, :numericality => true
  
  before_create :set_message
  
  scope :recent, lambda {|| where("created_at >= ?", Time.now - 2.days) }  
  scope :ordered, order("investigator_activities.created_at DESC")
  scope :activity, includes(:activity,:investigator)
  scope :news, lambda { |investigator| 
    activity.ordered.where("(namespace IN (?) AND investigator_id IN (?) ) OR (namespace IN (?) AND investigator_id = ?)",
          Activity::ALLY_NEWS_ACTIONS, investigator.inner_circle_ids, Activity::INVESTIGATOR_NEWS_ACTIONS, investigator.id)
  }
  
  attr_accessor :scope
    
  class << self
    def log(investigator, namespace, options={})
      activity = Activity.find_by_namespace(namespace)
      return nil unless activity
      
      investigator_activity = activity.investigator_activities.new(:investigator => investigator)
      investigator_activity.message = options[:message] unless options[:message].blank?
      investigator_activity.actor = options[:actor]
      investigator_activity.object = options[:object]
      investigator_activity.subject = options[:subject]
      investigator_activity.scope = options[:scope]
      investigator_activity.save
      investigator_activity
    end
  end
  
private

  def set_message
    self.message ||= activity.merge_message(self)
  end    
end  