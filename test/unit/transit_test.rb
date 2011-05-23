require 'test_helper'

class TransitTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @transit = transits(:arkham_new_york)
  end
  
  def create_effections_for_travel
    possession = @investigator.possessions.create!( :item => items(:hand_of_glory), :origin => 'gift' ) 
    possession.send(:create_effects)
    effects(:hand_of_glory_discount_travel).effections.update_all(:begins_at => Time.now - 1.hour) # update so that time comparisons are true
  end
  
  test 'travel!' do
    flexmock(Transit).new_instances.should_receive(:cost_of_travel).and_return(@transit.price)
    assert_difference ['@investigator.funds'], -@transit.price do
      assert Transit.travel!(@investigator, locations(:new_york).id)
      @investigator.reload
    end
    assert_equal locations(:new_york), @investigator.location
  end
  
  test 'travel! with missing destination' do
    assert_no_difference ['@investigator.funds','InvestigatorActivity.count'] do
      assert !Transit.travel!(@investigator, 99)
      assert @investigator.errors[:base].include?("Destination unavailable")
    end
    assert_equal locations(:arkham), @investigator.location
  end
  
  test 'travel! without funds' do
    @investigator.update_attribute(:funds, 0)
    assert_no_difference ['@investigator.funds','InvestigatorActivity.count'] do
      assert !Transit.travel!(@investigator, locations(:new_york).id)
    end
    assert @investigator.errors[:base].include?("Destination travel costs too expensive")
    assert_equal locations(:arkham), @investigator.location    
  end
  
  test 'investigator activity on travel!' do
    assert_difference ['InvestigatorActivity.count'], +1 do
      assert Transit.travel!(@investigator, locations(:new_york).id)
    end
  end
  
  test 'log_travel' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @transit.log_travel @investigator
  end
  
  test 'effect_bonus' do
    assert_equal 0, @transit.send(:effect_bonus, @investigator)
    
    create_effections_for_travel
    expected = effects(:hand_of_glory_discount_travel).power
    assert_equal expected, @transit.send(:effect_bonus, @investigator)
  end  
  
  test 'cost_of_travel' do
    assert_equal @transit.price, @transit.cost_of_travel(@investigator)
  end

  test 'cost_of_travel with effects' do
    flexmock(@transit).should_receive(:effect_bonus).and_return(1)
    assert_equal @transit.price - 1, @transit.cost_of_travel(@investigator)
  end

  test 'cost_of_travel minimum' do
    flexmock(@transit).should_receive(:effect_bonus).and_return(@transit.price + 1)
    assert_equal 0, @transit.cost_of_travel(@investigator)
  end
end