class Spellbook < ActiveRecord::Base
  belongs_to :grimoire
  belongs_to :investigator
  
  validates :grimoire_id, :presence => true
  validates :investigator_id, :presence => true
  validates :name, :presence => true
  
  before_validation :set_name, :on => :create  
  
  scope :read, where(:read => true)
  scope :unread, where(:read => false)
  scope :grimoire, includes(:grimoire => :spells)
  
  def read!
    return false if read?
    
    update_attribute(:read, true)
    log_reading
    investigator.award_madness!( grimoire.madness_cost )
  end
  
  def read?; read; end
  
private

  def set_name
    self.name = grimoire.name if grimoire
  end  
  
  def log_reading
    InvestigatorActivity.log investigator, 'grimoire.read', :subject => grimoire
  end  
end