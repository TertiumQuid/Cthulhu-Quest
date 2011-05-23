require 'test_helper'

class InvestigatorTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @item = items(:timepiece)
    @weapon = weapons(:colt_45_automatic)
    @armament = armaments(:aleph_colt_45_automatic)
    @medical = items(:first_aid_kit)
  end
  
  test 'skill methods' do
    [:adventure,:bureaucracy,:conflict,:research,:scholarship,
    :society,:sorcery,:underworld,:psychology,:sensitivity].each do |skill|
      assert @investigator.respond_to?(skill)
    end
  end
  
  test 'maxium_moxie' do
    @investigator.update_attribute(:level, 1)
    assert_equal 10, @investigator.maximum_moxie
    @investigator.update_attribute(:level, 20)
    assert_equal 10, @investigator.maximum_moxie
    @investigator.update_attribute(:level, 30)
    assert_equal 15, @investigator.maximum_moxie
  end
  
  test 'maximum_wounds' do
    @investigator.level = 1
    assert_equal 10, @investigator.maximum_wounds
    @investigator.level = 10
    assert_equal 11, @investigator.maximum_wounds
    @investigator.level = 19
    assert_equal 11, @investigator.maximum_wounds
    @investigator.level = 20
    assert_equal 12, @investigator.maximum_wounds
  end
  
  test 'maximum_madness' do
    @investigator.level = 1
    assert_equal 10, @investigator.maximum_madness
    @investigator.level = 10
    assert_equal 11, @investigator.maximum_madness
    @investigator.level = 19
    assert_equal 11, @investigator.maximum_madness
    @investigator.level = 20
    assert_equal 12, @investigator.maximum_madness
  end
    
  test 'possessions scopes uses_count' do
    possession = possessions(:aleph_lantern)
    assert @investigator.possessions.include?(possession)
    
    possession.update_attribute(:uses_count, nil)
    assert @investigator.reload.possessions.include?(possession)
    
    possession.update_attribute(:uses_count, 0)
    assert !@investigator.reload.possessions.include?(possession)
  end
    
  test 'purchase possesion' do
    @investigator.update_attribute(:funds, @item.price)
    assert_difference '@investigator.reload.funds', -@item.price do
      assert_difference 'Possession.count', +1 do
        purchase = @investigator.possessions.purchase!( @item ) 
        assert_equal @investigator.id, purchase.investigator_id
        assert_equal @item.id, purchase.item_id
      end
    end
  end
  
  test 'purchase possesion failure' do
    @investigator.update_attribute(:funds, 0)
    assert_no_difference ['Possession.count','@investigator.reload.funds'] do
      purchase = @investigator.possessions.purchase!( @item )
      assert !purchase.errors[:investigator_id].blank?
    end
  end  
  
  test 'purchase weapon' do
    @armament.destroy
    @investigator.update_attribute(:funds, @weapon.price)
    assert_difference '@investigator.reload.funds', -@weapon.price do
      assert_difference 'Armament.count', +1 do
        purchase = @investigator.armaments.purchase!( @weapon )
        assert_equal @investigator.id, purchase.investigator_id
        assert_equal @weapon.id, purchase.weapon_id
      end
    end
  end
  
  test 'purchase weapon failure' do
    @investigator.update_attribute(:funds, 0)
    assert_no_difference ['Possession.count','@investigator.reload.funds'] do
      purchase = @investigator.armaments.purchase!( @weapon )
      assert !purchase.errors[:investigator_id].blank?
    end
  end  
  
  test 'equip weapon' do
    assert_nil @investigator.armed
    assert @investigator.armaments.equip!( @armament.id )
    assert_equal @armament.weapon, @investigator.reload.armed.weapon
  end
  
  test 'set_profile' do
    Profile.all.each do |profile|
      investigator = Investigator.new(:profile_id => profile.id, :name => 'testing')
      assert investigator.send(:set_profile), "profile should be set"
      assert_equal profile.skills, investigator.stats.map(&:skill), "investigator should have same profile skills"
      assert_equal profile.name, investigator.profile_name, "investigator should have same profile name"
      assert_equal (profile.income * 7), investigator.funds, "investigator should have first week of funds"
      assert_equal 0, investigator.experience, "investigator should start with 0 experience"
      assert_equal 0, investigator.skill_points, "investigator should start with 0 skill points"
    end
  end
  
  test 'set_moxie' do
    investigator = Investigator.new(:profile_id => profiles(:librarian).id, :name => 'tester', :user_id => User.first.id)
    investigator.save
    assert_equal investigator.maximum_moxie, investigator.moxie
  end
  
  test 'set_location' do
    location = Location.find_by_name("Miskatonic Valley")
    investigator = Investigator.new(:profile_id => profiles(:librarian).id, :name => 'tester', :user_id => User.first.id)
    investigator.save
    assert_not_nil investigator.location_id
    assert_equal location.id, investigator.location_id
  end
  
  test 'set_plot_threads' do
    investigator = Investigator.new(:profile_id => Profile.first.id)
    assert investigator.send(:set_plot_threads), "journal should be set"
    assert !investigator.casebook.blank?, "journal should start with plots"
    assert_equal investigator.casebook.map(&:plot), 
                 Plot.find_starting_plots(investigator), "journal plots should be for starting investigator"
  end
  
  test 'set_user_investigator_id' do
    user = users(:aleph)
    investigator = user.investigator
    assert user.update_attribute(:investigator_id, nil), "nil investigator required"
    investigator.send(:set_user_investigator_id)
    assert_equal investigator.id, user.reload.investigator_id, "user should have investigator_id set"
  end
  
  test 'set_contacts' do
    Investigator.destroy_all
    user = users(:aleph)
    profile = profiles(:librarian)
    assert user.update_attribute(:investigator_id, nil), "nil investigator required"
    assert_difference 'Contact.count', +profile.characters.count do
      investigator = Investigator.create(:profile_id => profile.id, :name => 'tester', :user_id => user.id)
      assert_equal profile.characters, investigator.characters
      investigator.contacts.each { |c| assert_equal 3, c.favor_count }
    end
  end
  
  test 'create' do
    Investigator.destroy_all
    user = users(:aleph)
    assert user.update_attribute(:investigator_id, nil), "nil investigator required"
    investigator = Investigator.new(:profile_id => profiles(:librarian).id, :name => 'tester', :user_id => user.id)
    assert_difference 'Investigator.count', +1 do
      assert investigator.save
    end
    user.reload
    assert !investigator.skills.blank?, "new investigators should have profile skills"
    assert !investigator.plots.blank?, "new investigators shold have journal plots"
    assert_equal investigator.id, user.investigator_id, "user should have investigator_id set"
  end
  
  test 'validates name' do
    investigator = Investigator.new
    assert !investigator.valid?
    assert investigator.errors[:name].include?("is too short (minimum is 3 characters)")
    
  end
  
  test 'validates wounds' do
    @investigator.wounds = nil
    assert !@investigator.valid?
    assert @investigator.errors[:wounds].include?("is not a number")    
  end  
  
  test 'validates profile' do
    investigator = Investigator.new
    assert !investigator.valid?
    assert investigator.errors['profile_id'].include?("must be chosen")
  end
  
  test 'validates user' do
    investigator = Investigator.new
    assert !investigator.valid?
    assert investigator.errors['user_id'].include?("is not a number")
  end  
  
  test 'validates location' do
    investigator = Investigator.new
    assert !investigator.valid?
    assert investigator.errors['location_id'].blank?
    
    investigator.location_id = 'fail'
    assert !investigator.valid?
    assert investigator.errors['location_id'].include?("is not a number")
  end  
  
  test 'validates_no_investigator' do
    user = users(:aleph)
    investigator = user.build_investigator
    assert !investigator.valid?
    assert investigator.errors['user_id'].include?("already has active investigator")
  end
  
  test 'set_inner_circle' do
    friends = Investigator.joins("JOIN users ON investigators.user_id = users.id") 
    friends = friends.where(["users.facebook_id IN (?)", @investigator.user.facebook_friend_ids.split(',')])    
    
    Ally.destroy_all
    assert_operator friends.size, ">", 0
    assert_difference ['Ally.count','@investigator.inner_circle.count'], friends.size do
      @investigator.send(:set_inner_circle)
    end
  end
  
  test 'set_inner_circle ignored with existing friends' do
    @investigator.user.update_attribute(:facebook_friend_ids, users(:beth).facebook_id)
    friends = @investigator.user.facebook_friend_ids.split(',')
    assert_operator friends.size, ">", 0
    assert_no_difference ['Ally.count','@investigator.inner_circle.count'] do
      @investigator.send(:set_inner_circle)
    end
  end  
    
  test 'set_inner_circle without friends' do
    @investigator.user.update_attribute(:facebook_friend_ids, nil)
    Ally.destroy_all
    assert_no_difference 'Ally.count' do
      @investigator.send(:set_inner_circle)
    end
  end
  
  test 'income' do
    @investigator.level = 10
    assert_equal @investigator.profile.income + @investigator.level, @investigator.income
  end
  
  test 'earn_income!' do
    @investigator.update_attribute(:last_income_at, Time.now - 23.hours)
    assert_no_difference '@investigator.funds' do
      @investigator.earn_income!
    end
    
    @investigator.update_attribute(:last_income_at, Time.now - 25.hours)
    assert_difference '@investigator.funds', @investigator.income do
      @investigator.earn_income!
    end
    
    @investigator.update_attribute(:last_income_at, nil)
    assert_difference '@investigator.funds', @investigator.income do
      @investigator.earn_income!
    end  
    
    assert_no_difference '@investigator.funds', "investigator should not earn income twice" do
      @investigator.earn_income!
    end      
  end
  
  test 'award_experience!' do
    assert_difference '@investigator.reload.experience', +1 do
      @investigator.award_experience!(1)
    end
    
    assert_no_difference '@investigator.experience' do
      assert_difference '@investigator.experience', +1 do
        @investigator.award_experience!(1, :save => false)
      end
      @investigator.reload
    end
  end
  
  test 'award_experience! and advance' do
    assert_difference '@investigator.level', +1 do
      @investigator.award_experience!( @investigator.experience_until_next_level )
    end
  end
  
  test 'award_experience! and advance multiple levels' do
    @investigator.level = 2
    exp = @investigator.experience_until_next_level
    @investigator.level = 1
    assert_difference '@investigator.level', +2 do
      @investigator.award_experience!( exp )
    end
  end  
  
  test 'next_level_experience' do
    @investigator.level = 1
    assert_equal 12, @investigator.next_level_experience
    @investigator.level = 2
    assert_equal 27, @investigator.next_level_experience
    @investigator.level = 4
    assert_equal 61, @investigator.next_level_experience
    @investigator.level = 9
    assert_equal 165, @investigator.next_level_experience
    @investigator.level = 24
    assert_equal 562, @investigator.next_level_experience
    @investigator.level = 99
    assert_equal 3411, @investigator.next_level_experience
  end
  
  test 'experience_until_next_level' do
    [1,3,5].each do |level|
      @investigator.update_attribute(:level, level)
      @investigator.update_attribute(:experience, level * 7)
      expected = @investigator.next_level_experience - @investigator.experience
      assert_equal expected, @investigator.experience_until_next_level
    end
  end
  
  test 'advance_level' do
    assert_no_difference ['@investigator.level','@investigator.skill_points'] do
      assert_difference '@investigator.level', +1 do
        assert_difference '@investigator.skill_points', +10 do
          flexmock(@investigator).should_receive(:log_leveled).once
          @investigator.send(:advance_level)
        end
      end
      @investigator.reload
    end
  end
  
  test 'defense' do
    expected = (@investigator.stats.sum('skill_level') / Skill.count).ceil
    assert_equal expected, @investigator.defense
  end
  
  test 'power' do
    investigator = investigators(:beth_pi)
    investigator.level = 1
    assert_equal investigator.armed.weapon.power + 1, investigator.power
    
    investigator.level = 20
    assert_equal investigator.armed.weapon.power + 2, investigator.power
    
    investigator.armed_id = nil
    assert_equal 2, investigator.power
  end
  
  test 'attacks' do
    investigator = investigators(:beth_pi)
    assert_equal investigator.armed.weapon.attacks, investigator.attacks
    
    investigator.armed_id = nil
    assert_equal 1, investigator.attacks
  end
  
  test 'madness_status' do
    @investigator.maximum_madness.times do |n|
      @investigator.madness = n
      assert_not_nil @investigator.madness_status
    end
  end
  
  test 'wound_status' do
    @investigator.maximum_wounds.times do |n|
      @investigator.wounds = n
      assert_not_nil @investigator.wound_status
    end
  end
  
  test 'heal! self' do
    @investigator.update_attribute(:wounds, 1)
    possession = @investigator.possessions.create(:item_id => @medical.id, :origin => 'gift')
    
    assert_difference ['@investigator.wounds','@investigator.possessions.items.medical.count'], -1 do
      investigator = @investigator.heal!(possession)
      assert_equal @investigator.id, investigator.id
      @investigator.reload
    end
  end
  
  test 'heal! other' do
    friend = investigators(:gimel_pi)
    friend.update_attribute(:wounds, 1)
    @investigator.update_attribute(:wounds, 1)
    possession = @investigator.possessions.create(:item_id => @medical.id, :origin => 'gift')
    
    assert_difference ['friend.wounds','@investigator.wounds','@investigator.possessions.items.medical.count'], -1 do
      investigator = @investigator.heal!( possession, friend.id )
      assert_equal friend.id, investigator.id
      @investigator.reload
      friend.reload
    end
  end
  
  test 'heal! unwounded' do
    @investigator.update_attribute(:wounds, 0)
    possession = @investigator.possessions.create(:item_id => @medical.id, :origin => 'gift')
    
    assert_no_difference ['@investigator.wounds','@investigator.possessions.items.medical.count'] do
      @investigator.heal!(possession)
      assert @investigator.errors[:wounds].include?("already healed")
      @investigator.reload
    end    
  end
  
  test 'heal! without medical supplies' do
    @investigator.update_attribute(:wounds, 1)
    @investigator.possessions.destroy_all
    
    assert_no_difference ['@investigator.wounds'] do
      @investigator.heal!
      assert @investigator.errors[:wounds].include?("cannot be healed without medical supplies")
      @investigator.reload
    end    
  end  
  
  test 'requested_assignments' do
    assignee = investigators(:beth_pi)
    assignment = assignments(:aleph_grandfathers_journal_beth)
    assignment.update_attribute(:status, 'requested')
    
    assert_equal assignee, assignment.ally
    assert assignee.requested_assignments.include?(assignment)
    
    ['unanswered','accepted','refused'].each do |s|
      assignment.update_attribute(:status, s)
      assert !assignee.requested_assignments.include?(assignment)
    end
  end
  
  test 'requested_assignments for open investigation' do
    assignee = investigators(:beth_pi)
    assignment = assignments(:aleph_grandfathers_journal_beth)
    
    ['active','investigated'].each do |s|
      assignment.investigation.update_attribute(:status, s)
      assert assignee.requested_assignments.include?(assignment)
    end
  end
  
  test 'requested_assignments for closed investigation' do
    assignee = investigators(:beth_pi)
    assignment = assignments(:aleph_grandfathers_journal_beth)
    
    ['completed','solved','unsolved'].each do |s|
      assignment.investigation.update_attribute(:status, s)
      assert !assignee.requested_assignments.include?(assignment)
    end
  end
  
  test 'requested_assignments without allied' do  
    assert @investigator.allied_ids.blank?
    assert @investigator.requested_assignments.to_sql.include?('LIMIT 0')
    assert_equal 0, @investigator.requested_assignments.count
  end
  
  test 'spells' do
    spells = []
    Grimoire.all.each do |g|
      unless @investigator.grimoire_ids.include?(g.id)
        @investigator.spellbooks.create!(:grimoire_id => g.id, :read => true) 
      end
    end
    
    @investigator.grimoires.each do |g|
      g.spells.each do |s|
        spells << s unless spells.include?(s)
      end
    end
    assert !@investigator.spells.blank?
    assert_equal spells.size, @investigator.spells.all.size
    spells.each do |spell|
      assert @investigator.spells.include?(spell)
    end
  end
  
  test 'no spells' do  
    @investigator.spellbooks.destroy_all
    assert_equal [], @investigator.spells
  end
  
  test 'combat_fit?' do
    assert_equal true, @investigator.combat_fit?
    @investigator.wounds = @investigator.maximum_wounds
    assert_equal false, @investigator.combat_fit?
  end
  
  test 'can_introduce?' do
    character = characters(:thomas_malone)
    investigator = investigators(:gimel_pi)
    assert_equal true, @investigator.can_introduce?
    intro = @investigator.introducings.build(:character_id => character.id, :investigator_id => investigator.id, :message => 'intro', :status => 'arranged')
    intro.save(:validate => false)
    assert_equal false, @investigator.can_introduce?
    intro.update_attribute(:created_at, (Time.now - Introduction::TIMEFRAME.hours + 1.minute))
    assert_equal false, @investigator.can_introduce?
  end
  
  test 'maximum_plot_threads' do
    assert_equal 5, @investigator.maximum_plot_threads
    @investigator.level = 10
    assert_equal 5, @investigator.maximum_plot_threads
    @investigator.level = 20
    assert_equal 10, @investigator.maximum_plot_threads
  end
  
  test 'has_contact?' do
    contact = contacts(:aleph_henry_armitage)
    assert_equal false, @investigator.has_contact?(nil)
    assert_equal true, @investigator.has_contact?(contact.character_id)
    assert contact.destroy
    assert_equal false, @investigator.has_contact?(contact.character_id)
  end
  
  test 'log_creation on create' do
    user = users(:gimel)
    user.investigator.destroy
    user.update_attribute(:investigator_id, nil)
    investigator = Investigator.new(:name => 'test', :profile_id => profiles(:occultist).id, :user_id => user.id )
    flexmock(investigator).should_receive(:log_creation).once
    investigator.save!
  end
  
  test 'log_creation' do
    user = users(:gimel)
    investigator = Investigator.new(:name => 'test', :profile_id => profiles(:occultist).id, :user_id => user.id )
    flexmock(InvestigatorActivity).should_receive(:log).once
    investigator.send(:log_creation)
  end  
  
  test 'log_leveled' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @investigator.send(:log_leveled)
  end
  
  test 'castings current' do
    spell = spells(:sway_of_the_adept)
    casting = @investigator.castings.create!(:spell_id => spell.id)
    assert_equal casting, @investigator.castings.current
  end
  
  test 'retire!' do
    user = User.find( @investigator.user_id )
    investigators(:beth_pi).allies.create!(:ally => @investigator)
    
    assert_difference '@investigator.allied.count', -1 do
      assert @investigator.retire!
    end
    assert_nil user.reload.investigator_id
    
    assert_nothing_raised do
      @investigator.retire!
      assert_equal 0, @investigator.reload.user_id
    end
  end
  
  test 'recover_wounds!' do
    flexmock(@investigator).should_receive(:healing_effect_bonus).and_return(0).once
    @investigator.update_attribute(:wounds,2)
    
    assert_difference '@investigator.wounds', -1 do
      @investigator.recover_wounds!
    end
  end
  
  test 'recover_wounds! unwounded' do
    @investigator.update_attribute(:wounds,0)
    flexmock(@investigator).should_receive(:update_attribute).times(0)
    assert_no_difference '@investigator.wounds' do
      @investigator.recover_wounds!
    end
  end
  
  test 'recover_wounds! with excess' do
    @investigator.update_attribute(:wounds,1)
    @investigator.update_attribute(:level,100)
    assert_difference '@investigator.wounds', -1 do
      @investigator.recover_wounds!
    end    
  end
  
  test 'healing_effect_bonus' do
    assert_equal 0, @investigator.healing_effect_bonus
    
    possession = @investigator.possessions.create!( :item => items(:rod_of_asclepius), :origin => 'gift' ) 
    possession.send(:create_effects)
    effects(:rod_of_asclepius_restore_health).effections.update_all(:begins_at => Time.now - 1.hour) # update so that time comparisons are true
    expected = effects(:rod_of_asclepius_restore_health).power
    assert_equal expected, @investigator.healing_effect_bonus
  end
  
  test 'madness_effect_bonus' do
    assert_equal 0, @investigator.madness_effect_bonus
    
    possession = @investigator.possessions.create!( :item => items(:sigillum_dei_aemeth), :origin => 'gift' ) 
    possession.send(:create_effects)
    effects(:sigillum_dei_aemeth_resist_madness).effections.update_all(:begins_at => Time.now - 1.hour) # update so that time comparisons are true
    expected = effects(:sigillum_dei_aemeth_resist_madness).power
    assert_equal expected, @investigator.madness_effect_bonus
  end
  
  test 'award_madness!' do
    assert_difference '@investigator.madness', +2 do
      @investigator.award_madness!(2)
    end
  end
  
  test 'award_madness! with madness_effect_bonus' do  
    flexmock(@investigator).should_receive(:madness_effect_bonus).and_return(1).once
    assert_difference '@investigator.madness', +1 do
      @investigator.award_madness!(2)
    end    
  end
  
  test 'all_stats' do
    all_stats = @investigator.all_stats
    assert_equal Skill.count, all_stats.size
    
    @investigator.stats.each do |s|
      assert all_stats.include?(s)
    end
    
    all_stats.each do |s|
      if s.new_record?
        assert_equal @investigator.id, s.investigator_id
        assert_equal 0, s.skill_points
      else
        assert @investigator.stats.include?(s)
      end
    end
  end
  
  test 'insane?' do
    @investigator.psychoses_count = nil
    assert_equal false, @investigator.insane?
    @investigator.psychoses_count = 0
    assert_equal false, @investigator.insane?
    @investigator.psychoses_count = 1
    assert_equal true, @investigator.insane?
  end
  
  test 'available_socials' do
    alliance = allies(:aleph_beth)
    social = socials(:beth_estate_auction)
    
    assert !alliance.ally.socials.blank?
    assert_equal [], alliance.investigator.available_socials
    
    alliance.ally.allies.create!(:ally => alliance.investigator)
    assert_equal [social], alliance.investigator.available_socials
  end
  
  test 'wounded?' do
    @investigator.wounds = 0
    assert_equal false, @investigator.wounded?
    
    @investigator.wounds = 1
    assert_equal true, @investigator.wounded?
  end
  
  test 'maddened?' do
    @investigator.madness = 0
    assert_equal false, @investigator.madness?
    
    @investigator.madness = 1
    assert_equal true, @investigator.madness?
  end  
  
  test 'destitute?' do
    @investigator.funds = 0
    assert_equal true, @investigator.destitute?
    
    @investigator.funds = 1
    assert_equal false, @investigator.destitute?
  end  
  
  test 'skill_by_name' do
    stat = stats(:aleph_research)
    assert_equal stat.skill_level, @investigator.skill_by_name('Research')
    assert_equal stat.skill_level, @investigator.skill_by_name('research')
    
    stat.update_attribute(:skill_level, 0)
    assert_equal 0, @investigator.reload.skill_by_name('Research')
    
    stat.destroy
    assert_equal 0, @investigator.reload.skill_by_name('Research')    
  end
  
  test 'skill_by_id' do
    stat = stats(:aleph_research)
    assert_equal stat.skill_level, @investigator.skill_by_id(stat.skill_id)
    
    stat.update_attribute(:skill_level, 0)
    assert_equal 0, @investigator.reload.skill_by_id(stat.skill_id)
    
    stat.destroy
    assert_equal 0, @investigator.reload.skill_by_id(stat.skill_id)    
  end  
end