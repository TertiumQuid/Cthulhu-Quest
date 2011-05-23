class Tasking < ActiveRecord::Base
  OWNERS = ['Location','Character']
  
  belongs_to :task
  belongs_to :owner, :polymorphic => true
  has_many   :efforts, :dependent => :destroy
  
  scope :task, includes(:task => :skill)
  
  def available_for?(investigator)
    investigator && investigator.level >= level
  end  
  
  def viable_for?(investigator)
    investigator && investigator.skill_by_id(task.skill_id) > 0
  end
  
  def last_effort_for(investigator)
    efforts.new(:investigator => investigator).send(:last_effort)
  end
  
  def location?
    (owner_type || '').downcase == 'location'
  end
  
  def success_target_for(investigator)
    investigator ? [investigator.send( task.skill.name.downcase ) - difficulty, 0].max : 0
  end  
  
end