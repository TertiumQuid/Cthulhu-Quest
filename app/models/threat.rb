class Threat < ActiveRecord::Base
  belongs_to :plot
  belongs_to :intrigue
  belongs_to :monster
  
  def combat!( assignment )
    investigator = assignment.investigator
    assignment.build_combat(:monster => monster, 
                            :investigator => investigator,
                            :assignment => assignment,
                            :weapon_id => investigator.armed_id ? investigator.armed.weapon_id : nil)
    assignment.save
  end
end