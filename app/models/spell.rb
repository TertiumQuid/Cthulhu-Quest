class Spell < ActiveRecord::Base
  KIND = ['empowerment']
  
  has_and_belongs_to_many :grimoires
  has_many :castings, :dependent => :destroy
  has_many :effects, :as => 'trigger'

  validates :target_id, :allow_blank => true, :numericality => true
  validates :name, :presence => true
  validates :effect, :presence => true
  validates :description, :presence => true
  validates :power, :numericality => true
  validates :duration, :numericality => true
  validates :kind, :inclusion => { :in => KIND }
  
  scope :empowerment, where(:kind => 'empowerment')
  scope :effects, includes(:effects)
end