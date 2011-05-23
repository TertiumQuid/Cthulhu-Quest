require 'test_helper'

class PlotThreadTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:gimel_pi)
    @plot = plots(:troubled_dreams)
    @thread = plot_threads(:aleph_grandfathers_journal)
    @solution = solutions(:troubled_dreams_embrace)
  end
  
  test 'set_status' do
    thread = PlotThread.new
    assert_equal 'available', thread.status, "new plot threads should have available status"
  end
  
  test 'create' do
    assert_no_difference ['Assignment.count'] do
      assert_difference ['PlotThread.count'], +1 do
        thread = @investigator.casebook.build(:plot_id => plots(:fire_in_the_sky).id )
        assert thread.save!, "plot thread should save"
        assert_equal 'available', thread.status
      end
    end
  end
  
  test 'available?' do
    @thread.update_attribute(:status, 'solved')
    assert_equal false, @thread.available?, "should not be available without available status"
    @thread.update_attribute(:status, 'available')
    assert_equal true, @thread.available?, "should be available with available status"
  end
    
  test 'investigating?' do
    @thread.update_attribute(:status, 'solved')
    assert_equal false, @thread.investigating?, "should not be investigating without investigating status"
    @thread.update_attribute(:status, 'investigating')
    assert_equal true, @thread.investigating?, "should be investigating with investigating status"
  end
  
  test 'solved?' do
    @thread.update_attribute(:status, 'investigating')
    assert_equal false, @thread.solved?, "should not be solved without investigating status"
    @thread.update_attribute(:status, 'solved')
    assert_equal true, @thread.solved?, "should be solved with solved status"
  end
  
  test 'validates investigator_id' do
    thread = PlotThread.new
    assert !thread.valid?
    assert thread.errors[:investigator_id].include?("is not a number")
  end
  
  test 'validates uniqueness' do
    thread = PlotThread.new(:investigator_id => @thread.investigator_id, :plot_id => @thread.plot_id)
    assert !thread.valid?
    assert thread.errors[:plot_id].include?("has already been taken")
  end
  
  test 'validates_investigator_level' do
    @thread.plot.update_attribute(:level, @thread.investigator.level + 1)
    thread = PlotThread.create(:investigator_id => @thread.investigator_id, :plot_id => @thread.plot_id)
    assert thread.errors[:base].include?("investigator level too low")
  end
  
  test 'use_items!' do
    prerequisite = prerequisites(:troubled_dreams_notebook)
    prerequisite.update_attribute(:plot_id, @thread.plot_id)
    @thread.investigator.possessions.create(:item_id => items(:notebook).id, :origin => 'gift')
    assert_difference ['Possession.count','@thread.investigator.possessions.count'], -1 do
      @thread.send(:use_items!)
    end
  end
  
  test 'reward_investigator!' do
    thread = plot_threads(:aleph_troubled_dreams)
    funds = rewards(:troubled_dreams_funds)
    exp = rewards(:troubled_dreams_experience)
    
    thread.update_attribute(:status, 'solved')
    assert_difference ['thread.investigator.funds'], +funds.reward_id do
      assert_difference ['thread.investigator.experience'], +exp.reward_id do
        thread.reward_investigator!
        thread.investigator.reload
      end
    end
  end
  
  test 'reward_investigator! unsolved' do
    thread = plot_threads(:aleph_troubled_dreams)
    thread.update_attribute(:status, 'investigating')
    
    assert_no_difference ['thread.investigator.funds'] do
      assert_no_difference ['thread.investigator.experience'] do
        thread.reward_investigator!
        thread.investigator.reload
      end
    end
  end    
  
  test 'set_plot_title' do
    thread = PlotThread.create(:plot_id => @plot.id)
    assert_equal @plot.title, thread.plot_title
  end  
  
  test 'completed_assignments' do
    assert_equal 0, @thread.send(:completed_assignments)
    assert_equal 2, plot_threads(:beth_zohar).send(:completed_assignments)
    assert_equal 2, plot_threads(:beth_zohar).assignments.successful.group("intrigue_id").flatten.size
  end
  
  test 'percent_complete' do
    assert @thread.percent_complete.is_a?(Integer)
    assert_equal 0, PlotThread.new(:plot => @plot).percent_complete
    
    full_count = @thread.plot.intrigues.size
    half_count = ( full_count.to_f / 2.0 ).to_i
    flexmock(@thread).should_receive(:completed_assignments).and_return( half_count )
    assert_equal 50, @thread.percent_complete 
    
    flexmock(@thread).should_receive('plot.intrigues.size').and_return( half_count ).once
    assert_equal 100, @thread.percent_complete
    
    flexmock(@thread).should_receive('plot.intrigues.size').and_return( 1 ).once
    assert_equal 100, @thread.percent_complete
  end
end