class Stat < ActiveRecord::Base
  belongs_to :investigator
  belongs_to :skill

  validates :skill_id, :numericality => true
  validates :skill_points, :numericality => true
  validates :skill_level, :numericality => true
  
  scope :positive, where('skill_level > 0')
  
  before_validation :set_skill_name, :on => :create
  
  def increment!(num=1)
    num = num.to_i
    num = [next_level_skill_points,num].min
    
    if investigator.skill_points >= num
      self.skill_points = skill_points + num
      
      investigator.update_attribute(:skill_points, investigator.skill_points - num)
      
      if skill_points >= next_level_skill_points
        advance_level! 
      else
        save
      end
      log_advancement
    else
      errors[:investigator_id] << "cannot be advanced without enough skill points"
    end
    return skill_level
  end
  
  def obtained?(points)
    skill_points >= (next_level_skill_points - points)
  end
  
  def next_level_skill_points
    case skill_level
      when 0
        30
      when 1
        25
      when 2
        20
      else
        (skill_level < 10) ? 15 : 25
    end 
  end
  
private

  def advance_level!
    self.skill_points = 0
    self.skill_level = skill_level + 1
    save
  end
  
  def set_skill_name
    self.skill_name = skill.name if skill
  end
  
  def log_advancement
    InvestigatorActivity.log investigator, 'skill.advanced', :object => skill, :scope => skill_level
  end
end