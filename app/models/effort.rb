class Effort < ActiveRecord::Base
  belongs_to :tasking
  belongs_to :investigator
  
  validates :tasking_id, :presence => true
  validates :investigator_id, :presence => true    
  
  validate  :validates_level, :on => :create
  validate  :validates_location, :on => :create  
  validate  :validates_cooldown, :on => :create
  
  before_create :perform!
  
  scope :tasking, includes(:tasking)  
  
  def succeeded?
    return nil unless challenge_target && challenge_score
    challenge_score <= challenge_target
  end
  
  def perform!
    self.challenge_target = success_target
    self.challenge_score = random
    
    success = challenge_target > 0 && (challenge_score <= challenge_target)
    award! if success
  end
  
  def award!
    case tasking.task.task_type
      when 'funds'
        award_funds
    end
  end  
  
private

  def random
    rand( Task::CHALLENGE_RANGE ) 
  end
  
  def success_target
    [investigator.send( tasking.task.skill.name.downcase ) - tasking.difficulty, 0].max
  end  

  def validates_level
    return unless tasking && investigator
    errors[:base] << "level #{tasking.level} required to perform" unless tasking && tasking.available_for?(investigator)
  end
  
  def validates_location
    return unless tasking && tasking.location?
    errors[:base] << "must travel to #{tasking.owner_name} to perform" unless located?
  end  

  def located?
    tasking.location? && tasking.owner_id == investigator.location_id
  end
  
  def validates_cooldown
    return unless investigator
    errors[:base] << "must wait until later to perform" if last_effort.exists?
  end

  def effect_bonus
    investigator.effections.active.effect.on_skills.where("effects.target_id = #{tasking.task.skill_id}").sum("effects.power").to_i
  end
  
  def last_effort
    effort = investigator.efforts.tasking
    effort = effort.where(["taskings.owner_id = ? AND taskings.owner_type = ?", tasking.owner_id, tasking.owner_type])
    effort.where(["created_at >= ?", Time.now - 1.day])
  end
  
  def award_funds
    investigator.funds = investigator.funds + tasking.reward_id
  end  
end