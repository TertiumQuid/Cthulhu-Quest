require 'test_helper'

class TaskingTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @tasking = taskings(:miskatonic_university_university_lecture)
  end
  
  test 'available_for?' do
    @investigator.update_attribute(:level, @tasking.level)
    assert_equal true, @tasking.available_for?(@investigator)
    
    @investigator.update_attribute(:level, @tasking.level + 1)
    assert_equal true, @tasking.available_for?(@investigator)
    
    @tasking.update_attribute(:level, @investigator.level + 1)
    assert_equal false, @tasking.available_for?(@investigator)
  end
  
  test 'location?' do
    assert_equal true, @tasking.location?
    
    @tasking.owner_type = 'character'
    assert_equal false, @tasking.location?
    
    @tasking.owner_type = nil
    assert_equal false, @tasking.location?    
  end
  
  test 'last_effort_for' do
    params = {:investigator => @investigator}
    flexmock(Effort).new_instances.should_receive(:last_effort).and_return('test').once
    assert_equal 'test', @tasking.last_effort_for(@investigator)
  end
  
  test 'viable_for?' do
    tasking = taskings(:arkham_astronomical_anomaly)
    stat = stats(:aleph_research)
    
    assert_equal true, tasking.viable_for?(@investigator)
    
    stat.update_attribute(:skill_level, 0)
    @investigator.reload
    assert_equal false, tasking.viable_for?(@investigator)
    
    stat.destroy
    assert_equal false, tasking.viable_for?(@investigator)    
  end
  
  test 'success_target_for' do
    investigator = investigators(:gimel_pi)
    stat = stats(:gimel_scholarship)
    
    assert_equal 0, @tasking.success_target_for(nil)
    
    expected = [stat.skill_level - @tasking.difficulty, 0].max
    assert_equal expected, @tasking.success_target_for(investigator)

    stat.destroy
    investigator.reload
    assert_equal 0, @tasking.success_target_for(investigator)
  end  
  
end