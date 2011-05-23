require 'test_helper'

class ActivityTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @activity = Activity.new
    @investigation = investigations(:aleph_investigating)
  end
  
  test 'facebook_post?' do
    assert_equal false, @activity.facebook_post?
    @activity.dashboard_news = "test"
    assert_equal true, @activity.facebook_post?
  end
  
  test 'set_passive on create' do
    flexmock(Activity).new_instances.should_receive(:set_passive).once
    activity = Activity.create
  end
  
  test 'set_passive' do
    assert_nil @activity.passive
    @activity.send(:set_passive)
    assert_equal false, @activity.passive
  end  
  
  test 'get_name_for' do
    plot = plots(:hellfire_club)
    assert_equal plot.title, @activity.send(:get_name_for, plot)
    assert_equal @investigator.name, @activity.send(:get_name_for, @investigator)
    assert_equal @investigation.plot_title, @activity.send(:get_name_for, @investigation)
    assert_equal '', @activity.send(:get_name_for, Array.new)
    assert_equal '', @activity.send(:get_name_for, nil)
    assert_equal '1', @activity.send(:get_name_for, 1)
  end
  
  test 'merge_message' do
    investigator_activity = InvestigatorActivity.new
    flexmock(@activity).should_receive(:sub_name).times(6)
    assert_equal @activity.message, @activity.merge_message( investigator_activity )
  end
  
  test 'sub_name' do
    text = 'test'
    @activity.message = "++#{text}++"
    flexmock(@activity).should_receive(:get_name_for).and_return('name')
    assert_equal text, @activity.send(:sub_name, text, nil)
    assert_nil @activity.send(:sub_name, nil, Object.new)
    assert_equal '++name++', @activity.send(:sub_name, text, Object.new)
    assert_equal '++name++', @activity.message
  end
end