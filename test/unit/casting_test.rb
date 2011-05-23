require 'test_helper'

class CastingTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @spell = spells(:sway_of_the_adept)
  end
  
  test 'completing' do
    casting = @investigator.castings.create!(:spell_id => @spell.id)
    assert @investigator.castings.completing.include?(casting)
    
    casting.update_attribute(:completed_at, Time.now + 1.minute)
    assert @investigator.reload.castings.completing.include?(casting)
    
    casting.update_attribute(:completed_at, Time.now - 1.minute)
    assert !@investigator.reload.castings.completing.include?(casting)
  end

  test 'set_spell' do
    casting = @investigator.castings.new(:spell_id => @spell.id)
    casting.send(:set_spell)
    assert_equal @spell.name, casting.name
  end
  
  test 'set_spell on create' do
    flexmock(Casting).new_instances.should_receive(:set_spell).once
    assert_nothing_raised do
      @investigator.castings.create(:spell_id => @spell.id)
    end
  end
  
  test 'validates_unique_spell' do
    casting = @investigator.castings.create!(:spell_id => @spell.id)
    casting.update_attribute(:completed_at, Time.now - 1.minute)
    duplicate = @investigator.castings.create(:spell_id => @spell.id)
    assert duplicate.errors[:spell_id].include?("has already been cast and is currently active")
  end
  
  test 'validates_investigator_free' do
    casting = @investigator.castings.create!(:spell_id => @spell.id)
    duplicate = @investigator.castings.create(:spell_id => @spell.id)
    assert duplicate.errors[:investigator_id].include?("is already preoccupied casting another spell")
  end
  
  test 'set_timestamps' do
    ts = Time.now
    flexmock(Time).should_receive(:now).and_return(ts)
    
    casting = @investigator.castings.create(:spell_id => @spell.id)
    ended_at = (Time.now + @spell.time_cost.hours + @spell.duration.hours)
    completed_at = (Time.now + @spell.time_cost.hours)
    
    assert_equal ended_at, casting.ended_at
    assert_equal completed_at, casting.completed_at
  end
  
  test 'create' do
    assert_difference 'Casting.count', +1 do
      casting = @investigator.castings.new(:spell_id => @spell.id)
      flexmock(casting).should_receive(:create_effects).once
      casting.save
    end
  end
  
  test 'create_effects' do
    timestamp = Time.now
    flexmock(Time).should_receive(:now).and_return(timestamp)
    @investigator.effections.destroy_all
    
    casting = @investigator.castings.new(:spell_id => @spell.id, :completed_at => timestamp)
    assert_difference ['@investigator.reload.effections.count'], +casting.spell.effects.count do
      casting.send(:create_effects)
    end    
    
    @investigator.effections.each do |effection| 
      assert_equal casting.completed_at.to_i, effection.begins_at.to_i
    end
  end
end