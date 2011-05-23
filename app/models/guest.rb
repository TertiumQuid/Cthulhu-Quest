class Guest < ActiveRecord::Base
  STATUS = ['cooperated','defected']
  
  belongs_to :social
  belongs_to :investigator
  
  validates :investigator_id, :numericality => true, :uniqueness => {:scope => :social_id}
  validates :status, :inclusion => { :in => STATUS }
  validate  :validates_ally, :on => :create
  
  scope :cooperating, where("status = 'cooperated'")
  scope :defecting,   where("status = 'defected'")
  
  after_create  :log_rsvp
  
  def cooperated?
    status == 'cooperated'
  end
  
  def defected?
    status == 'defected'
  end 
  
  def description
    defected? ? social.social_function.defection : social.social_function.cooperation
  end
  
private

  def validates_ally 
    if social && investigator && !social.investigator.inner_circle.include?( investigator )
      errors[:investigator_id] << "not allied with the host"
    end
  end
  
  def log_rsvp
    InvestigatorActivity.log social.investigator, 'socialfunction.rsvp', :actor => investigator, :subject => social
    InvestigatorActivity.log investigator, 'socialfunction.guest', :actor => social.investigator, :subject => social
  end
end