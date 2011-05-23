require 'action_view/helpers/date_helper'

class Investigator < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
    
  belongs_to :profile
  belongs_to :user
  belongs_to :location
  
  has_many   :journal, :class_name => 'InvestigatorActivity', :dependent => :destroy
  has_many   :casebook, :class_name => 'PlotThread', :dependent => :destroy do
    def solved?(plot_id)
      where(:plot_id => plot_id).where(:status => 'solved').exists?
    end
  end
  has_many   :plots, :through => :casebook
  has_many   :investigations, :through => :casebook
  
  has_many   :efforts, :dependent => :destroy
  
  has_many   :stats, :dependent => :destroy, :order => "skill_level DESC"
  has_many   :positive_stats, :class_name => 'Stat', :conditions => "skill_level > 0"
  has_many   :skills, :through => :stats
  
  has_many   :allies, :foreign_key => 'investigator_id', :dependent => :destroy
  has_many   :allied, :foreign_key => 'ally_id', :class_name => 'Ally', :dependent => :destroy
  has_many   :allied_followers, :class_name => 'Investigator', :through => :allied, :source => :investigator
  has_many   :inner_circle, :class_name => 'Investigator', :through => :allies, :source => :ally
  has_many   :contacts, :dependent => :destroy
  has_many   :characters, :through => :contacts
  has_many   :socials, :dependent => :destroy
  has_many   :guests, :dependent => :destroy
  
  has_many   :combats, :dependent => :destroy
  has_many   :psychoses, :dependent => :destroy, :class_name => 'Psychosis'
  has_many   :insanities, :through => :psychoses

  has_many   :introductions, :dependent => :destroy    
  has_many   :introducings, :class_name => 'Introduction', :foreign_key => 'introducer_id', :dependent => :destroy  
  has_many   :gifts, :dependent => :destroy    
  has_many   :giftings, :class_name => 'Gift', :foreign_key => 'sender_id', :dependent => :destroy      
      
  has_many   :assignments
  
  has_many   :spellbooks, :dependent => :destroy
  has_many   :grimoires, :through => :spellbooks
  has_many   :castings, :dependent => :destroy do
    def current
      completing.first
    end
  end
  
  belongs_to :armed, :class_name => 'Armament'
  has_many   :armaments, :dependent => :destroy do
    def equip!(armament_id)
      a = find( armament_id )
      a.investigator.armed_id = armament_id
      a.investigator.save
      return a
    end
    
    def purchase!(weapon)
      a = create(:weapon => weapon, :origin => 'purchase')
      a.investigator.update_attribute( :funds, a.investigator.funds - weapon.price ) unless a.new_record?
      return a
    end
  end
  has_many   :weapons, :through => :armaments
  
  has_many   :library, :class_name => 'Possession', :include => [:item], :conditions => "items.kind = 'book'"
  has_many   :possessions, :dependent => :destroy, :conditions => "possessions.uses_count IS NULL OR possessions.uses_count > 0" do
    def purchase!(item)
      p = create(:item => item, :origin => 'purchase')
      p.investigator.update_attribute( :funds, p.investigator.funds - item.price ) unless p.new_record?
      return p
    end
  end
  has_many   :items, :through => :possessions
  
  has_many   :effections, :dependent => :destroy
  
  before_validation :set_profile, :on => :create
  before_save       :set_plot_threads, :on => :create
  before_save       :set_location, :on => :create
  before_save       :set_moxie, :on => :create
  before_save       :set_contacts, :on => :create
  after_save        :set_user_investigator_id, :on => :create
  after_create      :set_inner_circle
  after_create      :log_creation
  
  validates :name, :length => { :minimum => 3, :maximum => 128 }
  validates :level, :numericality => true
  validates :wounds, :numericality => true
  validates :madness, :numericality => true
  validates :experience, :numericality => true
  validates :skill_points, :numericality => true  
  validates :moxie, :numericality => true
  validates :user_id, :numericality => true
  validates :location_id, :numericality => true, :allow_blank => true
  validates :profile_id, :numericality => {:message => 'must be chosen'}
  validate  :validates_no_investigator, :on => :create
  
  def retire!
    user && update_attribute(:user_id, 0) && user.update_attribute(:investigator_id, nil) && allied.destroy_all
  end
  
  def heal!(possession_or_id = nil, investigator_id = nil)
    item = possession_or_id.is_a?(Possession) ? possession_or_id : possessions.find_by_id( possession_or_id )
    investigator = investigator_id ? Investigator.find( investigator_id ) : self
    
    if item.blank?
      investigator.errors[:wounds] << "cannot be healed without medical supplies"
    elsif investigator.wounds < 1
      investigator.errors[:wounds] << "already healed"
    else  
      update_attribute(:wounds, [wounds - 1, 0].max)
      investigator.update_attribute(:wounds, [investigator.wounds - 2, 0].max) unless investigator_id.blank?
      item.destroy
    end
    investigator
  end
  
  def recover_wounds!
    wounds_recovered = (level.to_f/2).ceil + healing_effect_bonus
    update_attribute(:wounds, [wounds - wounds_recovered,0].max ) if wounds > 0
  end
  
  def earn_income!
    return if !last_income_at.blank? && last_income_at > Time.now - 1.day
    update_attributes(:funds => funds + income, :last_income_at => Time.now) if profile
  end
  
  def award_experience!(amount,opts={})
    self.experience = experience + amount
    while experience_until_next_level < 1
      advance_level
    end
    
    return if opts[:save] == false
    save
  end
  
  def next_level_experience
    (((level+1)**1.29) * 9).to_i - 10
  end
  
  def experience_until_next_level
    next_level_experience - experience
  end
  
  def percent_until_next_level
    ((experience.to_f / next_level_experience.to_f) * 100).to_i
  end
  
  def award_madness!(amount)
    amount = [amount - madness_effect_bonus, 0].max
    update_attribute(:madness, madness + amount) if amount > 0
    
    if maddened = driven_mad?
      update_attribute(:madness, 0) if Psychosis.award!( self )
    end
    maddened
  end
  
  def madness_effect_bonus
    effections.active.effect.sanity.sum("effects.power").to_i
  end
  
  def income
    profile.income + level
  end
  
  def defense
    (stats.sum('skill_level') / Skill.count).ceil.to_i
  end
  
  def power
    (level.to_f / 10).ceil.to_i + (armed_id ? armed.weapon.power : 0)
  end
  
  def attacks
    (armed_id ? armed.weapon.attacks : 1)
  end
  
  def maximum_plot_threads
    [(level / 2),5].max
  end
  
  def driven_mad?
    madness >= maximum_madness
  end
  
  def insane?
    !psychoses_count.nil? && psychoses_count > 0
  end
  
  def spellcasting?
    castings.completing.exists?
  end
  
  def available_socials
    Social.active.for_allies( allied_follower_ids )
  end
      
  def requested_assignments(opts={})
    return Assignment.limit(0) unless allied.exists?
    
    requested = Assignment.includes([:intrigue,:investigation]).requested
    requested = requested.investigating unless opts[:open] == false
    requested = requested.where( "assignments.ally_id = #{id}" )
    return requested
  end

  def spells
    s = Spell.select("DISTINCT(spells.id) AS uniq, spells.*")
    s = s.joins("JOIN grimoires_spells ON spell_id = spells.id")
    s = s.where(["grimoires_spells.grimoire_id IN (?)", grimoire_ids])
    s = s.joins("JOIN spellbooks ON spellbooks.grimoire_id = grimoires_spells.grimoire_id")
    s = s.where(["spellbooks.read = ?", true])
  end
  
  def has_contact?(character_id)
    !character_id.blank? && contacts.where(:character_id => character_id).exists?
  end
  
  def madness_status
    case madness
      when 0
        "Compos mentis"
      when 1
        "Reasonably self-possessed"
      when 2
        "Becoming eccentric"
      when 3
        "Suspiciously excitable"
      when 4
        "Rather disturbed and unwell"
      when 5
        "Visibly unhinged in the worst of light"
      when 6
        "Moonstruck with bizaare fits and episodes"
      when 7
        "Deranged and uncontrollable"
      when 8
        "Vigorously psychopathic"
      when 9
        "Demented by the grip of a consuming revelation"
      else
        "Imprisoned in an alternate reality built from perfect terror"
    end
  end
  
  def wound_status
    case wounds
      when 0 
        "Healthy and unharmed"
      when 1
        "A bit battered and done in"
      when 2
        "Scathed but yet unscarred"
      when 3
        "Bloodied and begrimed"        
      when 4
        "Injured by grisly wounds"
      when 5
        "Carrying broken bones and agonizing visceral pains"
      when 6
        "Maimed and dressed in blood"
      when 7
        "Weeping blood and bile from gaping wound-holes"
      when 8
        "Fractured bones 'neath a skinless mess of gore"
      when 9
        "A broken skeleton garbed in the tatters of a human"
      else
        "Only the power of will preserves this body's ruined shambles"
    end
  end
  
  def wounded?
    wounds > 0
  end
  
  def maddened?
    madness > 0
  end  
  
  def destitute?
    funds == 0
  end
  
  def combat_fit?
    wounds < maximum_wounds
  end
  
  def can_introduce?
    !introducings.where(["created_at > ?", (Time.now - Introduction::TIMEFRAME.hours) ]).exists?
  end

  def maximum_wounds
    10 + (level / 10).ceil
  end
  
  def maximum_madness
    10 + (level / 10).ceil
  end  
  
  def maximum_moxie
    [(level / 2).floor, 10].max
  end
  
  def all_stats
    unskilled_ids = Skill.where(["id NOT IN (SELECT skill_id FROM stats WHERE investigator_id = ?)", id])
    stats + unskilled_ids.collect {|s| stats.new(:skill_id => s.id, :skill_name => s.name) } 
  end
  
  def adventure; skill_by_name('adventure') end
  def bureaucracy; skill_by_name('bureaucracy') end
  def conflict; skill_by_name('conflict') end
  def research; skill_by_name('research') end
  def scholarship; skill_by_name('scholarship') end
  def society; skill_by_name('society') end
  def sorcery; skill_by_name('sorcery') end
  def underworld; skill_by_name('underworld') end
  def psychology; skill_by_name('psychology') end
  def sensitivity; skill_by_name('sensitivity') end

  def skill_by_name(skill)
    stats.each do |s|
      return s.skill_level if skill.downcase == s.skill_name.downcase
    end
    return 0
  end
  
  def skill_by_id(skill_id)
    stats.each do |s|
      return s.skill_level if skill_id == s.skill_id
    end
    return 0
  end  
  
  def healing_effect_bonus
    effections.active.effect.healing.sum("effects.power").to_i
  end
  
  def next_income_at_in_words
    last_income_at ? distance_of_time_in_words( last_income_at, last_income_at + 1.day) : 'now'
  end
      
private  

  def advance_level  
    self.level = level + 1
    self.skill_points = skill_points + 10
    log_leveled
  end

  def set_user_investigator_id
    user.update_attribute(:investigator_id, id) if id && user
  end
  
  def set_profile
    return unless profile_id
    self.profile_name = profile.name
    profile.profile_skills.each do |s|
      self.stats.build(:skill_id => s.skill_id, :skill_level => s.skill_level, :skill_name => s.skill_name)
    end
    
    self.funds = profile.income * 7
    self.experience = 0
    self.skill_points = 0
  end
  
  def set_moxie
    self.moxie = maximum_moxie if new_record?
  end
  
  def set_location
    self.location = Location.find_by_name("Miskatonic Valley") if new_record?
  end
  
  def set_plot_threads
    return unless new_record?
    starting = Plot.find_starting_plots(self)
    starting.each do |plot|
      casebook.build(:plot_id => plot.id)
    end
  end
  
  def set_inner_circle
    circle_count = inner_circle.count
    return unless circle_count < Ally::MAX_ALLIES && !user.facebook_friend_ids.blank?
    
    circle = Investigator.joins("JOIN users ON investigators.user_id = users.id") 
    circle = circle.where(["users.facebook_id IN (?)", user.facebook_friend_ids.split(',')])
    circle = circle.limit(Ally::MAX_ALLIES - circle_count)
    circle.each do |ally|
      allies.create( :ally_id => ally.id )
    end
  end
  
  def set_contacts
    return unless new_record? && profile
    profile.characters.each do |character|
      contacts.build(:character_id => character.id, :favor_count => 3)
    end
  end
  
  def log_creation
    InvestigatorActivity.log self, 'registered'
  end
  
  def log_leveled
    InvestigatorActivity.log self, 'level', :scope => level
  end
  
  def validates_no_investigator
    if user && !user.investigator_id.blank?
      errors[:user_id] << "already has active investigator"
    end
  end
end