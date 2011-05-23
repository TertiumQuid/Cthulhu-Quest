require 'test_helper'

class EffortTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @tasking = taskings(:miskatonic_university_university_lecture)
    @effort = @investigator.efforts.new(:tasking => @tasking)
  end
  
  def create_effections_for_task_skill
    effect = effects(:chant_of_thoth_enhance_skill)
    @investigator.effections.create!(:effect => effect, :begins_at => Time.now - 1.hour, :ends_at => Time.now + 1.day )
  end
    
  test 'effect_bonus' do
    assert_equal 0, @effort.send(:effect_bonus)
  
    create_effections_for_task_skill
    expected = effects(:chant_of_thoth_enhance_skill).power
    assert_equal expected, @effort.send(:effect_bonus)
  end
  
  test 'succeeded?' do
    assert_nil @effort.succeeded?
    
    @effort.challenge_target = 1
    assert_nil @effort.succeeded?
    
    @effort.challenge_score = 2
    assert_equal false, @effort.succeeded?    
    
    @effort.challenge_score = 0
    assert_equal true, @effort.succeeded?    
  end
  
  test 'located?' do
    assert_equal false, @effort.send(:located?)
    
    @tasking.update_attribute(:owner_id, @investigator.location_id)
    assert_equal true, @effort.send(:located?)
    
    @tasking.update_attribute(:owner_type, 'character')
    assert_equal false, @effort.send(:located?)    
  end
  
  test 'validates_level' do
    expected = "level #{@tasking.level} required to perform"
    
    @tasking.update_attribute(:level, @effort.investigator.level - 1)
    @effort.valid?
    assert !@effort.errors[:base].include?(expected)
    
    @tasking.update_attribute(:level, @effort.investigator.level + 1)
    @effort.valid?
    assert @effort.errors[:base].include?(expected)
  end
  
  test 'validates_location' do
    expected = "must travel to #{@tasking.owner_name} to perform"
    
    @effort.valid?
    assert @effort.errors[:base].include?(expected)
    
    @tasking.update_attribute(:owner_id, @effort.investigator.location_id)
    @effort.valid?
    assert !@effort.errors[:base].include?(expected)
  end
  
  test 'validates_cooldown' do
    expected = "must wait until later to perform"
    
    flexmock(@effort).should_receive('last_effort.exists?').once.and_return(true)
    @effort.save
    assert @effort.errors[:base].include?(expected)
    
    flexmock(@effort).should_receive('last_effort.exists?').once.and_return(false)
    @effort.save
    assert !@effort.errors[:base].include?(expected)    
  end
    
  test 'last_effort' do
    alternate = taskings(:miskatonic_university_curate_exhibit)
    @effort.save(:validate => false)

    alt = @investigator.efforts.new(:tasking => alternate) 
    assert_equal true, alt.send(:last_effort).exists?
    
    @effort.update_attribute(:created_at, Time.now - 25.hours) && alt.save
    assert_equal false, alt.send(:last_effort).exists?
    
    @effort.update_attribute(:created_at, Time.now)
    @effort.tasking.update_attribute(:owner_id, 1) && alt.save
    assert_equal false, alt.send(:last_effort).exists?
  end
  
  test 'award_funds' do
    assert_no_difference '@effort.investigator.funds' do
      assert_difference '@effort.investigator.funds', +@tasking.reward_id do
        @effort.send(:award_funds)
      end
      @effort.investigator.reload
    end  
  end  
  
  test 'award!' do
    flexmock(@effort).should_receive(:award_funds).once
    @effort.award!

    @effort.tasking.task.update_attribute(:task_type, 'moxie')
    @effort.award!
  end
  
  test 'perform! on create' do
    flexmock(@effort).should_receive(:validates_level)
    flexmock(@effort).should_receive(:validates_location)
    flexmock(@effort).should_receive(:validates_cooldown)
    
    flexmock(@effort).should_receive(:perform!).once
    @effort.save!
    
    invalid = Effort.new
    flexmock(invalid).should_receive(:perform!).times(0)
    invalid.save
  end
  
  test 'perform! success' do
    flexmock(@effort).should_receive(:random).and_return(0)
    flexmock(@effort).should_receive(:success_target).and_return(1)
    flexmock(@effort).should_receive(:award!).once
    
    @effort.perform!
    assert_equal 1, @effort.challenge_target
    assert_equal 0, @effort.challenge_score
  end

  test 'perform! failure' do
    flexmock(@effort).should_receive(:random).and_return(1)
    flexmock(@effort).should_receive(:success_target).and_return(0)
    flexmock(@effort).should_receive(:award!).times(0)
    
    @effort.perform!
    assert_equal 0, @effort.challenge_target
    assert_equal 1, @effort.challenge_score
  end
  
  test 'random' do
    assert_operator @effort.send(:random), ">=", 0
    assert_operator @effort.send(:random), "<=", Task::CHALLENGE_RANGE
  end
  
  test 'success_target' do
    investigator = investigators(:gimel_pi)
    stat = stats(:gimel_scholarship)
    effort = investigator.efforts.new(:tasking => @tasking)
    
    expected = [stat.skill_level - @tasking.difficulty, 0].max
    assert_equal expected, effort.send(:success_target)

    stat.destroy
    effort = investigator.efforts.new(:tasking => @tasking)
    assert_equal 0, effort.send(:success_target)
  end  
end