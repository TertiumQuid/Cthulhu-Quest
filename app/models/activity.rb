class Activity < ActiveRecord::Base
  ALLY_NEWS_ACTIONS = ['insanity.gained','social.function','plot_solved']
  INVESTIGATOR_NEWS_ACTIONS = ['wounds.received.healing','ally.allied','gifted.funds','gifted.item','investigation.assigned','contact.introduction','insanity.treated']
  
  has_many :investigator_activities
  
  validates :name, :presence => true
  validates :namespace, :presence => true
  validates :message, :presence => true
  validates :passive, :presence => true  
  
  before_validation :set_passive
      
  def facebook_post?
    !dashboard_news.blank?
  end
  
  def merge_message(investigator_activity)
    sub_name "<investigator>", investigator_activity.investigator
    sub_name "<location>", investigator_activity.investigator ? investigator_activity.investigator.location : nil
    sub_name "<actor>", investigator_activity.actor
    sub_name "<object>", investigator_activity.object
    sub_name "<subject>", investigator_activity.subject
    sub_name "<scope>", investigator_activity.scope
    message
  end
  
private

  def get_name_for(model)
    if model.nil?
      ''
    elsif model.is_a?(Integer)
      model.to_s
    elsif model.respond_to?(:name)
      model.name
    elsif model.respond_to?(:title)
      model.title
    elsif model.respond_to?(:plot_title)      
      model.plot_title
    else
      ''
    end
  end
  
  def sub_name(text,model)
    return text if text.blank? || model.blank? || !self.message.include?(text)
    self.message = self.message.gsub(text, get_name_for(model) )
  end

  def set_passive
    self.passive ||= false
  end  
end