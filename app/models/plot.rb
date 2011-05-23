class Plot < ActiveRecord::Base
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :characters
  has_many :intrigues, :dependent => :destroy, :order => 'ordinal ASC'
  has_many :prerequisites, :dependent => :destroy
  has_many :plot_threads, :dependent => :destroy
  has_many :solutions, :dependent => :destroy
  has_many :rewards, :dependent => :destroy
  has_many :threats, :dependent => :destroy

  scope :located_at, lambda { |location_id|
    joins("JOIN locations_plots ON plot_id = plots.id AND location_id = #{location_id.to_i}")
  }
  scope :assigned_by, lambda { |character_id|
    joins("JOIN characters_plots ON plot_id = plots.id AND character_id = #{character_id.to_i}")
  }  
  scope :available_for, lambda { |investigator|
    ids = investigator.plot_ids
    return where("id NOT IN (?) ", ids.blank? ? 0 : ids)
  }  
  scope :viable_for, lambda { |investigator|
    return where("level <= ?", investigator.level)
  }
  
  def available_for?(investigator)
    investigator && investigator.level >= level
  end
  
  def short_subtitle
    subtitle.gsub(/^Of /, '')
  end
  
  class << self
    def find_starting_plots(user=nil)
      names = ["Grandfather's Journal","Troubled Dreams"]
      where(["plots.title IN (?)", names])
    end
  end    
end