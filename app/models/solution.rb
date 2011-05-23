class Solution < ActiveRecord::Base
  KIND = ['heroic','sinister','insane','scientific','denial','neutral']
  
  belongs_to :plot
  has_many :plot_threads
  
  validates :plot_id, :presence => true, :numericality => true
  validates :title, :presence => true, :length => { :minimum => 3, :maximum => 128 }
  validates :description, :presence => true, :length => { :minimum => 3, :maximum => 512 }
  validates :kind, :presence => true, :inclusion => { :in => KIND }
end