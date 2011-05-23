require 'test_helper'

class MonsterTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @monster = monsters(:hound_of_tindalos)
  end
  
  test 'sanity_resistence_for' do
    assert_equal 0, @monster.sanity_resistence_for(@investigator)
  end
  
  test 'sanity_resistence_for with successes' do
    combats(:aleph_failed_acolyte).update_attribute(:monster_id, @monster.id)
    assert_equal 1, @monster.sanity_resistence_for(@investigator)
  end  
end