require 'test_helper'

class ThreatTest < ActiveSupport::TestCase
  def setup
    @threat = threats(:grandfathers_journal_acolyte)
    @assignment = assignments(:aleph_grandfathers_journal_self_4)
  end
  
  test 'combat!' do
    assert_difference 'Combat.count', +1 do
      @threat.combat! @assignment
      @assignment.reload
    end
    assert_not_nil @assignment.combat
    assert_equal @assignment.intrigue.threat.monster_id, @assignment.combat.monster_id
    assert_equal @assignment.investigator_id, @assignment.combat.investigator_id
  end
  
  test 'combat! armed' do
    @assignment.investigator.armed = armaments(:aleph_colt_45_automatic)
    @assignment.save
    @threat.combat! @assignment
    @assignment.reload
    
    assert !@assignment.investigator.armed.blank?
    assert_equal @assignment.combat.weapon_id, @assignment.investigator.armed.weapon_id
  end
end