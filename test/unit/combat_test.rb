require 'test_helper'

class CombatTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:beth_pi)
    @monster = monsters(:acolyte)
    @assignment = assignments(:aleph_grandfathers_journal_beth)
    
    Combat.destroy_all
    @combat = Combat.new(:investigator => @investigator, 
                         :monster => @monster, 
                         :assignment => @assignment)
  end
  
  def create_effections_for_combat
    possession = @investigator.possessions.create!( :item => items(:abraxas_stone), :origin => 'gift' ) 
    possession.send(:create_effects)
    effects(:abraxas_stone_enhance_defense).effections.update_all(:begins_at => Time.now - 90.minutes) # update so that time comparisons are true
  end
  
  test 'serializes logs' do
    log = {:text => 'true', :array => [], :hash => {:value => true}}
    @combat.logs = log
    @combat.result = 'succeeded'
    flexmock(@combat).should_receive(:resolve)
    assert @combat.save
    assert_equal log, @combat.reload.logs
  end
  
  test 'set_wounds on create' do
    flexmock(@combat).should_receive(:set_wounds).once
    @combat.save
  end
  
  test 'set_wounds' do
    combat = Combat.new
    assert_nil combat.wounds
    combat.send(:set_wounds)
    assert_equal 0, combat.wounds
  end  
  
  test 'random' do
    assert_operator @combat.send(:random), ">=", 0
    assert_operator @combat.send(:random), "<=", 10
  end  
  
  test 'hit? failure' do
    @monster.update_attribute(:defense, 3)
    flexmock(@investigator).should_receive(:power).and_return(1)
    flexmock(@combat).should_receive(:random).and_return(3)
    
    @combat.logs = []
    assert_difference '@combat.logs.size', +1 do
      assert !@combat.send(:hit?, @investigator, @monster, {:logs => true})
    end
  end
  
  test 'hit? success' do
    @monster.update_attribute(:defense, 1)
    flexmock(@investigator).should_receive(:power).and_return(2)
    flexmock(@combat).should_receive(:random).and_return(1)
    
    @combat.logs = []
    assert_difference '@combat.logs.size', +1 do
      assert @combat.send(:hit?, @investigator, @monster, {:logs => true})
    end
  end 
  
  test 'hit? with effects' do
    flexmock(@combat).should_receive(:attacker_power).with(@investigator).twice.and_return(1)
    flexmock(@combat).should_receive(:defender_power).with(@monster).twice.and_return(1)
    @combat.logs = []
    @combat.send(:hit?, @investigator, @monster)
  end
  
  test 'attack_loop_count' do
    @monster.update_attribute(:attacks, 1)
    @investigator.armed.weapon.update_attribute(:attacks, 2)
    assert_equal 2, @combat.send(:attack_loop_count)
    @monster.update_attribute(:attacks, 3)
    assert_equal 3, @combat.send(:attack_loop_count)
  end
  
  test 'set_weapon' do
    @combat.save
    assert_equal @combat.weapon_id, @combat.investigator.armed.weapon_id
  end
  
  test 'resolve success' do
    flexmock(@combat).should_receive(:hit?).and_return(true)
    flexmock(@combat).should_receive(:set_madness).once
    assert_difference ['@combat.investigator.wounds'], +1 do
      assert @combat.save
    end
    assert_not_nil @combat.logs
    assert_equal 'succeeded', @combat.result
    assert_equal @investigator.wounds, @combat.wounds
  end
  
  test 'resolve success unscathed' do
    flexmock(@combat).should_receive(:hit?).and_return(true)
    flexmock(@combat).should_receive(:set_madness).once
    @monster.update_attribute(:attacks, 0)
    assert_no_difference ['@combat.investigator.wounds'] do
      assert @combat.save
    end
    assert_equal "You defeated a #{@monster.name} unscathed.", @combat.logs.last
    assert_equal @investigator.wounds, @combat.wounds
  end  
  
  test 'resolve failure' do
    flexmock(@combat).should_receive(:random).and_return(1)
    flexmock(@combat).should_receive(:set_madness).once
    @monster.update_attribute(:defense, 99)
    @monster.update_attribute(:power, 99)
    assert_difference ['@combat.investigator.wounds'], +@combat.investigator.maximum_wounds do
      assert @combat.save
    end
    assert_equal 'failed', @combat.result
    assert_equal "A #{@monster.name} left you #{@investigator.wound_status} for #{@investigator.wounds}.", @combat.logs.last
    assert_equal @investigator.wounds, @combat.wounds
  end
  
  test 'attacker_power' do
    assert_equal @investigator.power, @combat.send(:attacker_power, @investigator)
  end
  
  test 'attacker_power with effects' do
    flexmock(@combat).should_receive(:effect_bonus).with('attack').and_return(1)
    assert_equal @investigator.power + 1, @combat.send(:attacker_power, @investigator)
  end  
  
  test 'attacker_power with contact' do
    contact = contacts(:aleph_henry_armitage)
    assert @combat.assignment.update_attribute(:contact_id, contact.id)
    expected = @investigator.power + contact.favor_count + 1
    assert_equal expected, @combat.send(:attacker_power, @investigator)
  end  
  
  test 'attacker_power with monster' do
    assert_equal @monster.power, @combat.send(:attacker_power, @monster)
  end
  
  test 'defender_power' do
    assert_equal @investigator.defense, @combat.send(:defender_power, @investigator)
  end 
  
  test 'defender_power with effects' do
    flexmock(@combat).should_receive(:effect_bonus).with('defense').and_return(1)
    assert_equal @investigator.defense + 1, @combat.send(:defender_power, @investigator)
  end   
  
  test 'defender_power with monster' do
    assert_equal @monster.defense, @combat.send(:defender_power, @monster)
  end
  
  test 'succeeded?' do
    assert_equal false, @combat.succeeded?
    @combat.result = 'failed'
    assert_equal false, @combat.succeeded?
    @combat.result = 'succeeded'
    assert_equal true, @combat.succeeded?
  end
  
  test 'bounty_hunting?' do
    assert_equal false, @combat.bounty_hunting?
    @combat.assignment_id = nil
    assert_equal true, @combat.bounty_hunting?
  end
  
  test 'award_bounty on create' do
    combat = Combat.new(:investigator => @investigator, 
                        :monster => @monster)
    flexmock(combat).should_receive(:award_bounty).once
    combat.save
  end
  
  test 'award_bounty with success' do
    combat = Combat.new(:investigator => @investigator, :monster => @monster)
    flexmock(combat).should_receive(:succeeded?).and_return(true)
    
    assert_difference '@investigator.reload.funds', +@monster.bounty do
      combat.send(:award_bounty)
    end
  end
  
  test 'no award_bounty with failure' do
    combat = Combat.new(:investigator => @investigator, :monster => @monster)
    flexmock(combat).should_receive(:succeeded?).and_return(false)
    
    assert_no_difference '@investigator.reload.funds' do
      combat.send(:award_bounty)
    end
  end  
  
  test 'log_battle on create' do
    flexmock(@combat).should_receive(:log_battle).once
    @combat.save!
  end
  
  test 'log_battle' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @combat.send(:log_battle)
  end
  
  test 'effect_bonus for attack' do
    assert_equal 0, @combat.send(:effect_bonus, 'attack')
    
    create_effections_for_combat
    expected = effects(:abraxas_stone_enhance_attack).power
    assert_equal expected, @combat.send(:effect_bonus, 'attack')
  end
  
  test 'effect_bonus for defense' do
    assert_equal 0, @combat.send(:effect_bonus, 'defense')
    
    create_effections_for_combat
    expected = effects(:abraxas_stone_enhance_defense).power
    assert_equal expected, @combat.send(:effect_bonus, 'defense')
  end  
  
  test 'set_madness' do
    @combat.logs = []
    flexmock(@combat).should_receive('monster.madness').and_return(3)
    flexmock(@combat).should_receive('monster.sanity_resistence_for').and_return(1).once
    
    assert_difference '@combat.logs.size', +1 do
      assert_difference '@combat.investigator.madness', +2 do
        assert_equal true, @combat.send(:set_madness)
        expected_log = "The horror of battle cost you 2 madness, but you became a little more cold and hardened."
        assert_equal expected_log, @combat.logs.last
      end
    end
  end
    
  test 'set_madness with no madness' do
    @combat.logs = []
    @combat.monster.update_attribute(:madness, 0)
    flexmock(Investigator).new_instances.should_receive(:award_madness!).times(0)
    flexmock(Investigator).new_instances.should_receive(:update_attribute).times(0)
    flexmock(Monster).new_instances.should_receive(:sanity_resistence_for).times(0)
    
    assert_no_difference '@combat.logs.size' do
      assert_nil @combat.send(:set_madness)
    end
  end
end