class Effection < ActiveRecord::Base
  belongs_to :effect
  belongs_to :investigator
  
  before_create :set_timestamps
  
  scope :active, lambda {|| where(["begins_at <= ? AND ends_at >= ?", Time.now, Time.now])}
  scope :effect, includes(:effect => :effecacy)
  scope :spells, where("effects.trigger_type = 'Spell'")
  
  scope :on_skills, where("effects.target_type LIKE 'Skill'")
  scope :on_attacks, where("effecacies.namespace = 'attacks.enhancement'")
  scope :on_attack, where("effecacies.namespace = 'attack.enhancement'")
  scope :on_defense, where("effecacies.namespace = 'defense.enhancement'")
  scope :on_combat, where("effecacies.namespace IN ('defense.enhancement','attack.enhancement','attacks.enhancement')") 
  scope :traveling, where("effecacies.namespace = 'travel.discount'")  
  scope :bonding, where("effecacies.namespace = 'social.bond'")
  scope :healing, where("effecacies.namespace = 'health.restoration'")
  scope :sanity, where("effecacies.namespace = 'madness.resist'")    
  
  def remaining_time_in_percent
    100 - (((Time.now - begins_at) / (ends_at - begins_at)) * 100).round
  end
      
private 

  def set_timestamps
    self.begins_at ||= Time.now
    self.ends_at = begins_at + effect.duration.hours
  end
end