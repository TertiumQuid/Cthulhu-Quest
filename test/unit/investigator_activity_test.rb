require 'test_helper'

class InvestigatorActivityTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @ally = investigators(:beth_pi)
    @activity = activities(:monster_combat)
    @investigator_activity = InvestigatorActivity.new(:activity => @activity)
  end
  
  test 'log' do
    activity = nil
    assert_difference 'InvestigatorActivity.count', +1 do
      activity = InvestigatorActivity.log(@investigator, @activity.namespace)
    end
    assert activity.is_a?(InvestigatorActivity)
    assert_equal @investigator, activity.investigator
    assert_equal @activity, activity.activity
    assert_equal false, activity.read
  end
  
  test 'log with options' do
    monster = monsters(:acolyte)
    scope = 1
    activity = InvestigatorActivity.log(@investigator, @activity.namespace, :actor => monster, :subject => monster, :object => monster, :scope => scope, :message => 'test')
    assert_equal monster, activity.actor
    assert_equal monster, activity.subject
    assert_equal monster, activity.object
    assert_equal scope, activity.scope
    assert_equal 'test', activity.message
  end

  test 'log without activity' do
    assert_nil InvestigatorActivity.log(@investigator, 'bad.namespace')
  end
  
  test 'set_message' do
    msg = 'test'
    flexmock(@activity).should_receive(:merge_message).and_return(msg).once
    @investigator_activity.send(:set_message)
    assert_equal msg, @investigator_activity.message
  end
  
  test 'set_message ignored' do
    msg = 'test'
    old = 'tested'
    @investigator_activity.message = old 
    flexmock(@activity).should_receive(:merge_message).and_return(msg).times(0)
    @investigator_activity.send(:set_message)
    assert_equal old, @investigator_activity.message
  end
  
  test 'news scope' do
    sql =  InvestigatorActivity.news(@investigator).to_sql
    expected = "WHERE ((namespace IN (#{ Activity::ALLY_NEWS_ACTIONS.collect{|a| "'#{a}'"}.join(',') }) "
    expected = expected + "AND investigator_id IN (#{@investigator.inner_circle_ids.join(',')}) ) "
    expected = expected + "OR (namespace IN (#{ Activity::INVESTIGATOR_NEWS_ACTIONS.collect{|a| "'#{a}'"}.join(',') }) AND investigator_id = #{@investigator.id})"
    assert sql.include?(expected)

    @investigator.inner_circle.each do |i|
      Activity::ALLY_NEWS_ACTIONS.each do |n|
        InvestigatorActivity.log(i, n, options={})
      end
    end
    assert !InvestigatorActivity.news(@investigator).blank?
  end
end
