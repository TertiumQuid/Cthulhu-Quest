class Prerequisite < ActiveRecord::Base
  TYPES = ['plot','item','funds']
  
  belongs_to :plot
  
  validates :plot_id, :numericality => true  
  validates :requirement_id, :numericality => true  
  validates :requirement_name, :length => { :minimum => 1, :maximum => 256 }
  validates :requirement_type, :length => { :minimum => 1, :maximum => 256 }, :inclusion => { :in => TYPES }
  
  scope :items, where("requirement_type = 'item'")
  
  class << self      
    def validate_investigation(investigation)
      solved_ids = nil
      item_ids = nil
      plot = investigation.plot
      investigator = investigation.investigator
      success = true
    
      plot.prerequisites.each do |p|
        case p.requirement_type
          when 'plot'
            solved_ids = investigator.casebook.solved.map(&:plot_id) if solved_ids.nil?
            unless p.send(:solved_plot?, investigator, solved_ids)
              investigation.errors[:base] << "hasn't solved required plot: #{p.requirement_name}"
              success = false
            end
          when 'item'
            item_ids = investigator.item_ids if item_ids.nil?
            unless p.send(:has_item?, investigator, item_ids)
              investigation.errors[:base] << "you don't posses the required item: #{p.requirement_name}"
              success = false
            end
          when 'funds'
            unless p.send(:has_funds?, investigator)
              investigation.errors[:base] << "you don't posses enough funds: £#{p.requirement_id}"
              success = false
            end
        end
      end
      
      return success
    end
  end
  
  def satisfied?(investigator, item_ids=nil)
    case requirement_type
      when 'plot'
        return solved_plot?( investigator )
      when 'item'
        return has_item?( investigator, item_ids )
      when 'funds'
        return has_funds?( investigator )
      else
        nil
    end
  end
      
  def requirement
    case requirement_type
      when 'plot'
        return Plot.find_by_id( requirement_id )
      when 'item'
        return Item.find_by_id( requirement_id )
      when 'funds'
        return requirement_id
      else
        nil
    end
  end
  
private

  def solved_plot?(investigator, solved_ids=nil)
    solved_ids = investigator.casebook.solved.map(&:plot_id) if solved_ids.nil?
    return solved_ids.include?( requirement_id )
  end

  def has_item?(investigator, item_ids=nil)
    if item_ids.nil?
      investigator.possessions.where(:item_id => requirement_id).exists?
    else
      item_ids.include?( requirement_id )
    end
  end  
  
  def has_funds?(investigator)
    return investigator.funds >= requirement_id
  end
end