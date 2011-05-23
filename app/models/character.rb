class Character < ActiveRecord::Base
  has_and_belongs_to_many :plots
  belongs_to :user
  belongs_to :location
  has_many :character_skills
  has_many :contacts
  has_and_belongs_to_many :profiles
  
  scope :location, includes(:location)
  
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
    character_skills.each do |s|
      return s.skill_level if skill.downcase == s.skill_name.downcase
    end
    return 0
  end    
end