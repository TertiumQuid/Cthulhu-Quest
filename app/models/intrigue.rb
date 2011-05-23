class Intrigue < ActiveRecord::Base
  THRESHOLD_BASE = 5
  CHALLENGE_RANGE = 20
  
  has_many :assignments
  has_one :threat, :dependent => :destroy
  belongs_to :challenge, :class_name => 'Skill'
  belongs_to :plot
  
  validates :difficulty, :numericality => true
  validates :title, :length => { :minimum => 3, :maximum => 128 }
  
  scope :challenge, includes(:challenge)
  scope :threat, includes(:threat)

  def threshold(investigator, ally_investigator=nil, contact_character=nil)
    skill = opposition_score(investigator, ally_investigator, contact_character)
    
    modifier = skill - difficulty
    return [ (THRESHOLD_BASE + modifier), 0 ].max
  end
  
  def opposition_score(investigator, ally_investigator=nil, contact_character=nil)
    skill = skill_level( investigator )
    skill += skill_level( ally_investigator ) if ally_investigator
    skill += skill_level( contact_character ) if contact_character
    [skill,CHALLENGE_RANGE].min
  end

  def insanity_penalty(assignable)
    assignable.psychoses.insanity.where(["insanities.skill_id = ?", challenge_id]).sum("severity").to_i * 3
  end
  
  def wound_penalty(assignable)
    assignable.wounds
  end
  
  def effect_bonus(assignable)
    if assignable
      assignable.effections.active.effect.on_skills.where("effects.target_id = #{challenge_id}").sum("effects.power").to_i
    else
      0
    end
  end
  
private
  
  def skill_level( assignable )
    skill = assignable.send( challenge.name.downcase )
    if assignable.is_a?( Investigator )
      skill = skill - insanity_penalty( assignable )
      skill = skill - wound_penalty( assignable )
      skill = skill + effect_bonus( assignable )
    end
    return [skill, 0].max
  end
end