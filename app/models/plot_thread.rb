class PlotThread < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  STATUS = ['available','investigating','solved']
  
  belongs_to :plot
  belongs_to :investigator
  belongs_to :solution
  has_many   :investigations do
    def active
       where("status <> 'solved' AND status <> 'unsolved'")
    end
    
    def final
      where("status = 'solved'").first
    end
  end
  has_many   :assignments, :through => :investigations
  
  after_initialize  :set_status
  before_validation :set_plot_title,  :on => :create
  
  scope :available, where("status = 'available'")
  scope :solved, where("status = 'solved'")
  scope :open, where("status = 'investigated' OR status = 'investigating'")
  scope :unsolved, where("status <> 'solved'")
  scope :plot, includes(:plot => {:prerequisites=>{},:rewards=>{},:intrigues=>[:challenge]})
  scope :solution, includes(:solution)  
  
  validates :investigator_id, :numericality => true
  validates :plot_id, :presence => true, :numericality => true, :uniqueness => {:scope => :investigator_id}
  validate  :validates_investigator_level, :on => :create
  validate  :validates_investigator_plot_limit, :on => :create
  
  def available?
    (status == 'available')
  end
  
  def investigating?
    (status == 'investigating')
  end 
  
  def solved?
    (status == 'solved')
  end
  
  def unsolved?
    (status == 'unsolved')
  end

  def use_items!
    plot.prerequisites.items.each do |pre|
      item = investigator.possessions.find_by_item_id( pre.requirement_id )
      item.use! if item
    end
  end
  
  def reward_investigator!
    return unless solved?
    
    plot.rewards.each do |reward|
      reward.award!( investigator )
    end
    investigator.save
  end
  
  def percent_complete
    [( (completed_assignments / plot.intrigues.size.to_f) * 100 ).to_i, 100].min
  end
  
private

  def completed_assignments
    assignments.successful.map(&:intrigue_id).uniq.size.to_f
  end

  def validates_investigator_level
    if new_record? && plot && investigator && (investigator.level < plot.level)
      errors[:base] << "investigator level too low"
    end
  end
  
  def validates_investigator_plot_limit
  end
  
  def set_status
    self.status ||= 'available' if new_record?
  end

  def set_plot_title
    self.plot_title = plot.title if plot
  end
end