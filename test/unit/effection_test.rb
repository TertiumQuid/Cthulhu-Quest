require 'test_helper'

class EffectionTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @effect = effects(:abramelin_oil_hasten_casting)
  end
  
  test 'create' do
    assert_difference 'Effection.count', +1 do
      @effect.effections.create(:investigator => @investigator)
    end
  end
  
  test 'set_timestamps' do
    timestamp = Time.now
    flexmock(Time).should_receive(:now).and_return(timestamp)
    effection = @effect.effections.new(:investigator => @investigator)
    
    effection.send(:set_timestamps)
    assert_equal timestamp, effection.begins_at
    assert_equal (timestamp + @effect.duration.hours), effection.ends_at
  end
  
  test 'set_timestamps with begins_at' do
    timestamp = Time.now
    effection = @effect.effections.new(:investigator => @investigator)  
    
    effection.begins_at = timestamp
    effection.send(:set_timestamps)
    assert_equal timestamp, effection.begins_at
  end  
  
  test 'remaining_time_in_percent' do
    effection = @effect.effections.new(:investigator => @investigator)

    effection.begins_at = Time.now
    effection.ends_at = Time.now + 1.hour
    assert_equal 100, effection.remaining_time_in_percent
    
    effection.begins_at = Time.now - 1.hour
    effection.ends_at = Time.now + 1.hour
    assert_equal 50, effection.remaining_time_in_percent
    
    effection.begins_at = Time.now - 1.hour
    effection.ends_at = Time.now
    assert_equal 0, effection.remaining_time_in_percent
  end
end
