require 'test_helper'

class SocialTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @social_function = social_functions(:dinner_reception)
    @guest = guests(:aleph_beth_estate_auction)
    @social = socials(:beth_estate_auction)
  end
  
  def create_effections_for_bonding
    possession = @social.investigator.possessions.create!( :item => items(:charmstone), :origin => 'gift' ) 
    possession.send(:create_effects)
  end  
  
  def new_valid_social
    investigators(:gimel_pi).socials.new(:social_function => social_functions(:estate_auction))
  end
  
  test 'serializes logs' do
    social = new_valid_social
    log = {:host_reward => "investigator hosted and recovered 2 wounds", :guest_rewards => []}
    
    social.logs = log
    assert social.save
    assert_equal log, social.reload.logs
  end
  
  test 'default_logs' do
    expected = {:host_reward => nil, :guest_rewards => []}
    assert_equal expected, Social.new.send(:default_logs)
  end
  
  test 'create' do
    social = new_valid_social
    flexmock(social).should_receive(:log_social).once
    assert social.save
  end
  
  test 'validates investigator_id' do
    social = Social.new
    assert !social.valid?
    assert social.errors['investigator_id'].include?("is not a number")
  end  
  
  test 'validates social_function_id' do
    social = Social.new
    assert !social.valid?
    assert social.errors['social_function_id'].include?("is not a number")
  end  
  
  test 'validates name' do
    social = Social.new
    assert !social.valid?
    assert social.errors['name'].include?("is too short (minimum is 1 characters)")
  end  
  
  test 'set_name on create' do
    social = @investigator.socials.create!(:social_function => @social_function)
    assert_equal @social_function.name, social.name
    
    assert social.update_attribute(:name, 'variant')
    assert_equal 'variant', social.reload.name
  end
  
  test 'set_logs on create' do
    social = @investigator.socials.create!(:social_function => @social_function)
    expected = {}
    assert_equal expected, social.logs
  end  
  
  test 'set_appointment_at on create' do
    expected = (Time.now + SocialFunction::TIMEFRAME.hours)
    social = @investigator.socials.create!(:social_function => @social_function)
    assert_not_nil social.appointment_at
    assert_operator social.appointment_at, ">=", expected
    
    flexmock(social).should_receive(:set_appointment_at).times(0)
    assert social.save
  end  
  
  test 'host!' do
    expected = Time.now
    flexmock(Time).should_receive(:now).and_return(expected)
    social = @investigator.socials.create!(:social_function => @social_function)
    flexmock(social).should_receive(:hosted?).and_return(false).once
    flexmock(social).should_receive(:scheduled?).and_return(true).once
    flexmock(social).should_receive(:reward_host).once
    flexmock(social).should_receive(:reward_guests).once
    flexmock(social).should_receive(:log_hosted).once    
    
    assert_nil social.hosted_at
    assert_equal true, social.host!
    assert_equal expected.to_i, social.reload.hosted_at.to_i
    assert_equal social.send(:default_logs), social.logs
  end
  
  test 'host! failure if already hosted' do
    social = @investigator.socials.create!(:social_function => @social_function)
    flexmock(social).should_receive(:hosted?).and_return(true).once
    flexmock(social).should_receive(:reward_guests).times(0)
    assert_equal false, social.host!
    assert social.errors[:base].include?("already hosted")
  end  
  
  test 'host! failure if unscheduled' do
    social = @investigator.socials.create!(:social_function => @social_function)
    flexmock(social).should_receive(:scheduled?).and_return(false).once
    flexmock(social).should_receive(:reward_guests).times(0)
    assert_equal false, social.host!
    assert social.errors[:base].include?("is not yet scheduled")
  end  
  
  test 'validates_no_active_social on create' do
    @investigator.socials.destroy_all
    original = @investigator.socials.create!(:social_function => @social_function)
    
    social = @investigator.socials.create(:social_function => @social_function)
    assert social.errors[:base].include?("You are already hosting another active social function.")
    assert original.save
  end
  
  test 'hosted?' do
    social = Social.new
    assert_equal false, social.hosted?
    social.hosted_at = Time.now
    assert_equal true, social.hosted?
  end  
  
  test 'scheduled?' do
    social = Social.new
    assert_equal false, social.scheduled?
    social.appointment_at = Time.now + 1.minute
    assert_equal false, social.scheduled?
    social.appointment_at = Time.now - 1.minute
    assert_equal true, social.scheduled?
    social.hosted_at = Time.now
    assert_equal false, social.scheduled?
  end
  
  test 'reward_host' do
    social = socials(:beth_estate_auction)
    social.logs = social.send(:default_logs)
    assert_operator social.guests.size, ">", 0
    
    flexmock(social).should_receive(:host_message).and_return('test')
    flexmock(social).should_receive(:defector_count).and_return(0).once
    social.send(:reward_host)
    assert_equal 'test', social.logs[:host_reward]
  end
  
  test 'reward_guests' do
    social = socials(:beth_estate_auction)
    social.logs = social.send(:default_logs)
    guest_count = social.guests.size
    
    assert_operator guest_count, ">", 0
    assert_difference 'social.logs[:guest_rewards].size', +guest_count do
      flexmock(social).should_receive(:reward_guest).times( social.guests.count ).and_return('message')
      flexmock(social).should_receive(:guest_message).times( social.guests.count ).and_return('message')
      flexmock(social).should_receive(:defector_count).and_return(0).once
      
      social.send(:reward_guests)
      social.logs[:guest_rewards].each do |m|
        assert_equal 'message', m
      end
    end
  end
  
  test 'reward_guest' do
    social = socials(:beth_estate_auction)
    flexmock(social).should_receive('social_function.reward_investigator').and_return("rewarded").once
    assert_equal "rewarded", social.send(:reward_guest, @guest, 1)
    assert_equal "rewarded", @guest.reload.reward
  end
  
  test 'guest_score' do
    social = @guest.social
    assert_equal 2, social.send(:guest_score, @guest, 0)
    @guest.status = 'cooperated'
    assert_equal 1, social.send(:guest_score, @guest, 1)
    @guest.status = 'defected'
    assert_equal 3, social.send(:guest_score,@guest, 1)
    assert_equal 0, social.send(:guest_score,@guest, 2)
  end
  
  test 'log_social' do
    social = Social.new
    flexmock(InvestigatorActivity).should_receive(:log).once
    social.send(:log_social)
  end  
  
  test 'log_hosted' do
    social = Social.new
    flexmock(InvestigatorActivity).should_receive(:log).once
    social.send(:log_hosted)
  end  
  
  test 'scheduled_at_in_words' do
    social = @investigator.socials.create!(:social_function => @social_function)
    
    social.update_attribute(:created_at, Time.now - 2.hours)
    assert_equal "about 2 hours", social.scheduled_at_in_words
    
    social.update_attribute(:appointment_at, Time.now)
    social.update_attribute(:created_at, Time.now - 5.hours)
    assert_equal "ready", social.scheduled_at_in_words
    
    social.update_attribute(:hosted_at, Time.now - 1.hour)
    assert_equal "about 1 hour ago", social.scheduled_at_in_words
  end
  
  test 'remaining_time_in_percent' do
    social = @investigator.socials.create!(:social_function => @social_function)
    
    social.created_at = Time.now
    assert_equal 100, social.remaining_time_in_percent
    
    social.created_at = Time.now - (SocialFunction::TIMEFRAME / 2).hours
    assert_equal 50, social.remaining_time_in_percent
    
    social.created_at = Time.now - SocialFunction::TIMEFRAME.hours
    assert_equal 0, social.remaining_time_in_percent
  end  
  
  test 'host_message' do
    expected = "As the host of the #{@social.social_function.name}, #{@social.investigator.name} test"
    assert_equal expected, @social.send(:host_message, 'test')
  end
  
  test 'guest_message' do
    expected = "#{@investigator.name} was test guest at #{@social.investigator.name}'s #{@social.social_function.name} and test"
    assert_equal expected, @social.send(:guest_message, @investigator, 'test', 'test')
  end
  
  test 'log_guest_reward' do
    @social.logs = @social.send(:default_logs)
    assert_difference 'InvestigatorActivity.count', +1 do
      log = @social.send(:log_guest_reward, @investigator, 'test')
      assert_equal ['test'], @social.logs[:guest_rewards]
      assert_equal @social, log.subject
      assert_equal @investigator, log.investigator
      assert_equal @social.investigator, log.actor
      assert_equal 'test', log.message
    end
  end

  test 'defector_count' do
    flexmock(@social).should_receive('effect_bonus').and_return(0).once
    flexmock(@social).should_receive('guests.defecting.count').and_return(0).once
    assert_equal 0, @social.send(:defector_count)
  end

  test 'defector_count with defectors' do
    flexmock(@social).should_receive('effect_bonus').and_return(0).once
    flexmock(@social).should_receive('guests.defecting.count').and_return(3).once
    assert_equal 3, @social.send(:defector_count)
  end
  
  test 'defector_count with effect_bonus' do
    flexmock(@social).should_receive('effect_bonus').and_return(1).once
    flexmock(@social).should_receive('guests.defecting.count').times(0)
    assert_equal 0, @social.send(:defector_count)
  end
  
  test 'effect_bonus' do
    assert_equal 0, @social.send(:effect_bonus)
    
    create_effections_for_bonding
    expected = effects(:charmstone_bond_social).power
    assert_equal expected, @social.send(:effect_bonus)
  end  
  
  test 'percent_complete' do
    assert @social.percent_complete.is_a?(Integer)
    
    assert_equal 0, Social.new(:social_function => @social_function, :created_at => Time.now).percent_complete    
    
    flexmock(@social).should_receive('remaining_time_in_percent').and_return( 50 ).once
    assert_equal 50, @social.percent_complete 

    flexmock(@social).should_receive('remaining_time_in_percent').and_return( 0 ).once
    assert_equal 100, @social.percent_complete 
  end
end