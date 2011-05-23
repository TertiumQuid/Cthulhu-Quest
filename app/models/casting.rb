class Casting < ActiveRecord::Base
  belongs_to :investigator
  belongs_to :spell
  
  before_validation :set_timestamps, :on => :create
  before_validation :set_spell, :on => :create
  after_create      :create_effects
  
  validates :investigator_id, :numericality => true
  validates :spell_id, :numericality => true
  validates :name, :presence => true
  validate  :validates_investigator_free, :on => :create
  validate  :validates_unique_spell, :on => :create
  
  scope :completing, lambda {|| where("completed_at > ?", Time.now)}
  scope :active, lambda {|| where("completed_at <= ? AND ended_at >= ?", Time.now, Time.now)}
  
  def completing?
    completed_at > Time.now
  end
    
private

  def validates_investigator_free
    if investigator && investigator.spellcasting?
      errors[:investigator_id] << "is already preoccupied casting another spell"
    end
  end
  
  def validates_unique_spell
    if investigator && investigator.castings.active.exists? && investigator.castings.active.map(&:spell_id).include?(spell_id)
      errors[:spell_id] << "has already been cast and is currently active"
    end
  end

  def set_timestamps
    self.ended_at ||= (Time.now + spell.time_cost.hours + spell.duration.hours)
    self.completed_at ||= (Time.now + spell.time_cost.hours)
  end
  
  def set_spell
    self.name ||= spell.name
  end

  def create_effects
    spell.effects.each do |effect|
      effect.effections.create(:investigator => investigator, :begins_at => completed_at)
    end
  end
end