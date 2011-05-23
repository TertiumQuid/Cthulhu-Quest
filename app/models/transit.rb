class Transit < ActiveRecord::Base
  MODE = ['bus','steamship','airplane','train']
  
  belongs_to :origin, :class_name => 'Location'
  belongs_to :destination, :class_name => 'Location'
  
  class << self
    def travel!(investigator, destination_id)
      transit = find_by_origin_id_and_destination_id(investigator.location_id, destination_id)
      
      if transit.blank?
        investigator.errors[:base] << "Destination unavailable"
      elsif (cost = transit.cost_of_travel(investigator) ) > investigator.funds
        investigator.errors[:base] << "Destination travel costs too expensive"
      else
        investigator.location_id = destination_id
        investigator.funds = investigator.funds - cost
        investigator.save
        transit.log_travel(investigator)
        return transit
      end
      return false
    end
  end
  
  def description
    if price > 0
      "Take the #{mode} to #{destination.name} for £#{price}"
    else
      "Move to #{destination.name}"
    end
  end

  def log_travel(investigator)
    InvestigatorActivity.log investigator, 'travel', :location => destination
  end  
  
  def cost_of_travel(investigator)
    [price - effect_bonus(investigator), 0].max
  end
  
  def effect_bonus(investigator)
    investigator.effections.active.effect.traveling.sum("effects.power").to_i
  end  
end