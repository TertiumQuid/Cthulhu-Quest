module Facebook::MonstersHelper
  def investigator_equals_monster_level(monster)
    current_investigator && current_investigator.level >= monster.level
  end
end