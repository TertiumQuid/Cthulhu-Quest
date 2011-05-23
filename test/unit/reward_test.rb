require 'test_helper'

class RewardTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
  end

  test 'award_experience_to' do
    reward = rewards(:troubled_dreams_experience)
    assert_no_difference '@investigator.experience' do
      assert_difference '@investigator.experience', +reward.reward_id do
        reward.send(:award_experience_to, @investigator)
      end
      @investigator.reload
    end
  end
  
  test 'award_funds_to' do
    reward = rewards(:grandfathers_journal_funds)
    assert_operator reward.reward_id, ">", 0
    assert_no_difference '@investigator.funds' do
      assert_difference '@investigator.funds', +reward.reward_id do
        reward.send(:award_funds_to, @investigator)
      end
      @investigator.reload
    end  
  end
  
  test 'award_item_to' do
    reward = rewards(:hellfire_club_signet_ring)
    assert_no_difference '@investigator.possessions.size' do
      assert_difference '@investigator.possessions.size', +1 do
        reward.send(:award_item_to, @investigator)
      end  
      @investigator.reload
    end
  end
  
  test 'award_grimoire_to' do
    @investigator.spellbooks.destroy_all
    reward = rewards(:fire_in_the_sky_eltdown_shards)
    assert_no_difference '@investigator.spellbooks.size' do
      assert_difference '@investigator.spellbooks.size', +1 do
        reward.send(:award_grimoire_to, @investigator)
      end  
      @investigator.reload
    end
  end  
  
  test 'award_plot_to' do
    reward = rewards(:the_golden_bough_emerald_tablet)
    flexmock(reward).should_receive(:award_plot_to).once
    reward.award!(@investigator)
  end
  
  test 'award_introduction_to' do
    reward = rewards(:thomas_malone_key_of_solomon)
    flexmock(reward).should_receive(:award_introduction_to).once
    reward.award!(@investigator)
  end  

  test 'award! grimoire' do
    @investigator.spellbooks.destroy_all
    reward = rewards(:fire_in_the_sky_eltdown_shards)
    assert_difference '@investigator.spellbooks.size', +1 do
      reward.award!(@investigator)
    end
    
    assert @investigator.save
    assert_no_difference '@investigator.spellbooks.size' do
      reward.award!(@investigator)
    end    
  end
  
  test 'award! funds' do
    reward = rewards(:grandfathers_journal_funds)
    assert_difference '@investigator.funds', +reward.reward_id do
      reward.award!(@investigator)
    end
  end
  
  test 'award! item' do
    reward = rewards(:hellfire_club_signet_ring)
    assert_difference '@investigator.possessions.size', +1 do
      reward.award!(@investigator)
    end
  end
  
  test 'award! plot' do  
    reward = rewards(:the_golden_bough_emerald_tablet)
    assert_difference '@investigator.casebook.size', +1 do
      reward.award!(@investigator)
    end      
    assert @investigator.casebook.map(&:plot_id).include?(reward.reward_id)
  end
  
  test 'award! experience' do
    reward = rewards(:troubled_dreams_experience)
    assert_difference '@investigator.experience', +reward.reward_id do
      reward.award!(@investigator)
    end
  end    
end