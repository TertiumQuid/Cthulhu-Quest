class Combat < ActiveRecord::Base
  RESULT = ['succeeded','failed']
  HIT_RANGE = 10
  
  belongs_to :monster
  belongs_to :investigator
  belongs_to :assignment
  belongs_to :weapon
  
  validates :monster_id, :numericality => true
  validates :investigator_id, :numericality => true
  
  before_create :set_weapon
  before_create :set_wounds
  before_create :resolve
  after_save    :award_bounty, :on => :create, :if => :bounty_hunting?
  after_create  :log_battle
  
  serialize :logs
  
  scope :threats, where('assignment_id IS NOT NULL')  
  scope :trophies, where(:wounds => 0).group("monster_id")
  scope :successes, where(:result => 'succeeded')
  
  def succeeded?
    result == 'succeeded'
  end  
  
  def bounty_hunting?
    assignment_id.nil?
  end
  
private  

  def set_weapon
    self.weapon_id ||= investigator.armed.weapon_id if investigator && investigator.armed
  end
  
  def set_wounds
    self.wounds ||= 0
  end
  
  def set_madness
    return unless monster && monster.madness > 0
    loss = [monster.madness - monster.sanity_resistence_for(investigator), 0].max
    if loss > 0
      logs << "The horror of battle cost you #{loss} madness, but you became a little more cold and hardened."
      investigator.award_madness!(loss)
    end
    true
  end
  
  def random
    rand( HIT_RANGE ) 
  end
    
  def resolve
    self.logs = []
    success = false
    self.wounds = 0
    
    while investigator.combat_fit? do
      attack_loop_count.times do |n|
        if investigator.attacks > n && hit?(investigator, monster)
          success = true
        end
        
        if monster.attacks > n && hit?(monster, investigator)
          investigator.wounds = investigator.wounds + 1
          self.wounds = self.wounds + 1
        end
      end
      break if success
    end
    
    investigator.save
    self.result = success ? 'succeeded' : 'failed'
    
    if wounds == 0
      logs << "You defeated a #{monster.name} unscathed."
    else
      logs << "A #{monster.name} left you #{investigator.wound_status} for #{wounds}."
    end
    set_madness
  end
  
  def attack_loop_count
    [investigator.attacks, monster.attacks].max
  end
  
  def hit?(attacker, defender, options={})
    score = random
    target = [( attacker_power(attacker) - defender_power(defender) ), 0].max
    success = score <= target
    logs << "#{attacker.name} attacked (defense #{defender_power(defender)}) against #{target} (attack #{attacker_power(attacker)}) and #{(success ? 'HIT' : 'MISSED')} with a #{score}."
    
    return success
  end
  
  def attacker_power(attacker)
    power = if !attacker.is_a?(Investigator)
      attacker.power
    elsif assignment_id && assignment.contact
      attacker.power + (assignment.contact.favor_count + 1) + effect_bonus('attack')
    else
      attacker.power + effect_bonus('attack')
    end
  end
  
  def defender_power(defender)
    power = if !defender.is_a?(Investigator)
      defender.defense
    else
      defender.defense + effect_bonus('defense')
    end
  end
  
  def effect_bonus(type)
    if type == 'defense'
      investigator.effections.active.effect.on_defense.sum("effects.power").to_i
    else
      investigator.effections.active.effect.on_attack.sum("effects.power").to_i
    end
  end
  
  def award_bounty
    investigator.update_attribute(:funds, investigator.funds + monster.bounty) if bounty_hunting? && succeeded?
  end
  
  def log_battle
    InvestigatorActivity.log investigator, 'monster.combat', :actor => monster
  end
end