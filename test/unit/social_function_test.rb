require 'test_helper'

class SocialFunctionTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @social_function = social_functions(:dinner_reception)
  end
  
  test 'reward_investigator with moxie' do
    @social_function.kind = 'moxie'
    flexmock(@social_function).should_receive(:reward_moxie).once
    desc = @social_function.reward_investigator(@investigator, 1)
    assert_equal "gained 1 moxie", desc
  end
  
  test 'reward_investigator with item' do
    @social_function.kind = 'item'
    possession = possessions(:aleph_lantern)
    flexmock(@social_function).should_receive(:reward_item).once.and_return(possession)
    desc = @social_function.reward_investigator(@investigator, 1)
    assert_equal "gained a lantern", desc
  end  
  
  test 'reward_investigator with sanity' do
    @social_function.kind = 'sanity'
    flexmock(@social_function).should_receive(:reward_sanity).once
    desc = @social_function.reward_investigator(@investigator, 1)
    assert_equal "recovered 1 sanity", desc
  end  
  
  test 'reward_investigator with health' do
    @social_function.kind = 'health'
    flexmock(@social_function).should_receive(:reward_health).once
    desc = @social_function.reward_investigator(@investigator, 1)
    assert_equal "recovered 1 wounds", desc
  end  
  
  test 'reward_moxie' do
    [0,1,2].each do |score|
      assert_difference '@investigator.moxie', +score do
        @social_function.send(:reward_moxie, @investigator, score)
        @investigator.reload
      end
    end
  end
  
  test 'reward_health' do
    @investigator.update_attribute(:wounds, 10)
    [0,1,2].each do |score|
      assert_difference '@investigator.wounds', -(score*2) do
        @social_function.send(:reward_health, @investigator, score)
        @investigator.reload
      end
    end
  end 
  
  test 'reward_sanity' do
    @investigator.update_attribute(:madness, 10)
    [0,1,2].each do |score|
      assert_difference '@investigator.madness', -score do
        @social_function.send(:reward_sanity, @investigator, score)
        @investigator.reload
      end
    end
  end   
  
  test 'reward_item' do
    @investigator.possessions.destroy_all
    price_limit = 1
    flexmock(@social_function).should_receive(:item_price_from_score).and_return(price_limit).once
    assert_difference '@investigator.possessions.count', +1 do
      @social_function.send(:reward_item, @investigator, 3)
    end    
    assert_equal price_limit, @investigator.possessions.first.item.price
  end
  
  test 'item_price_from_score' do
    assert_equal 5, @social_function.send(:item_price_from_score, 0)
    assert_equal 10, @social_function.send(:item_price_from_score, 1)
    assert_equal 50, @social_function.send(:item_price_from_score, 2)
    assert_equal 100, @social_function.send(:item_price_from_score, 3)
  end
end