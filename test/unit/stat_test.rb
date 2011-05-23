require 'test_helper'

class StatTest < ActiveSupport::TestCase
  def setup
    @stat = stats(:aleph_research)
  end
  
  test 'advance_level!' do
    @stat.update_attribute(:skill_points, 3)
    assert_difference '@stat.skill_points', -3 do
      assert_difference '@stat.skill_level', +1 do
        @stat.send(:advance_level!)
        @stat.reload
      end
    end
  end
  
  test 'obtained?' do
    @stat.update_attribute(:skill_points, 1)
    needed = @stat.next_level_skill_points
    assert_equal false, @stat.obtained?(needed - 2)
    assert_equal true, @stat.obtained?(needed - 1)
    assert_equal true, @stat.obtained?(needed)
  end
  
  test 'increment! without skills points' do  
    @stat.investigator.update_attribute(:skill_points, 0)
    assert_no_difference ['@stat.skill_points','@stat.investigator.skill_points'] do
      level = @stat.increment!
      @stat.reload
      assert_equal level, @stat.skill_level
      assert !@stat.errors[:investigator_id].blank?
    end
  end
  
  test 'increment!' do
    @stat.investigator.update_attribute(:skill_points, 3)
    flexmock(@stat).should_receive(:log_advancement).once
    assert_no_difference '@stat.skill_level' do
      assert_difference '@stat.investigator.skill_points', -1 do
        assert_difference '@stat.skill_points', +1 do
          level = @stat.increment!
          @stat.reload
          assert_equal level, @stat.skill_level
        end
      end
    end
  end
    
  test 'increment! with multiple points' do
    @stat.investigator.update_attribute(:skill_points, 3)
    flexmock(@stat).should_receive(:log_advancement).once
    assert_difference '@stat.investigator.skill_points', -2 do
      assert_difference '@stat.skill_points', +2 do
        level = @stat.increment!(2)
        @stat.reload
        assert_equal level, @stat.skill_level
      end    
    end
  end
  
  test 'increment! with excess' do  
      @stat.investigator.update_attribute(:skill_points, 100)
      flexmock(@stat).should_receive(:log_advancement).once
      
      assert_difference '@stat.investigator.skill_points', -@stat.next_level_skill_points do
        assert_no_difference '@stat.skill_points' do
          level = @stat.increment!(100)
          @stat.reload
          assert_equal level, @stat.skill_level
        end    
      end
    end    
  
  test 'increment with string' do
    assert_nothing_raised do
      @stat.increment!('2')
    end
  end
  
  test 'increment and create new stat' do  
    investigator = investigators(:aleph_pi)
    investigator.update_attribute(:skill_points, 5)
    stat = investigator.stats.new(:skill_id => skills(:bureaucracy).id)
    
    assert_difference 'investigator.stats.count', +1 do
      assert_difference 'investigator.skill_points', -1 do
        stat.increment!
        investigator.reload
        stat.reload
      end
    end  
    assert_equal 1, stat.skill_points
    assert_equal 0, stat.skill_level
  end
  
  test 'increment! and advance_level!' do
    @stat.investigator.update_attribute(:skill_points, 1)
    @stat.update_attribute(:skill_points, @stat.next_level_skill_points - 1)
    assert_difference '@stat.skill_level', +1 do
      @stat.increment!
      @stat.reload
    end
  end
  
  test 'next_level_skill_points' do
    stat = Stat.new
    
    stat.skill_level = 0
    assert_equal 30, stat.next_level_skill_points
    
    stat.skill_level = 1
    assert_equal 25, stat.next_level_skill_points    
    
    stat.skill_level = 2
    assert_equal 20, stat.next_level_skill_points    

    [3,4,5,6,7,8,9].each do |n|
      stat.skill_level = n
      assert_equal 15, stat.next_level_skill_points    
    end
    
    [10,11].each do |n|
      stat.skill_level = n
      assert_equal 25, stat.next_level_skill_points
    end
  end
  
  test 'log_advancement' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @stat.send(:log_advancement)
  end  
end