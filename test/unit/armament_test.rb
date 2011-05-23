require 'test_helper'

class ArmamentTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @weapon = weapons(:colt_45_automatic)
  end
  
  test 'set_weapon_name' do
    armament = @investigator.armaments.create(:weapon_id => @weapon.id)
    assert_equal @weapon.name, armament.weapon_name, "armament should inherit weapon name"
  end  
  
  test 'origin' do
    origin = 'purchase'
    armament = Armament.new( :origin => origin )
    assert_equal origin, armament.origin, "origin should be attr_accessor"
  end
  
  test 'arm_investigator after create' do
    @investigator.armaments.destroy_all
    armament = @investigator.armaments.create!(:weapon_id => @weapon.id)
    assert_equal armament, @investigator.reload.armed
    
    @investigator.armaments.create!(:weapon_id => weapons(:winchester_m1895_rile).id)
    assert_equal armament, @investigator.reload.armed
  end
  
  test 'validates weapon_name' do
    armament = Armament.new
    assert !armament.valid?
    assert armament.errors[:weapon_name].include?("can't be blank")
  end  
  
  test 'valid_purchase?' do
    assert_nil Armament.new.send(:valid_purchase?)
    assert_nil Armament.new( :weapon_id => @weapon.id ).send(:valid_purchase?)
    
    @investigator.update_attribute( :funds, (@weapon.price - 1) )
    assert_equal false, Armament.new( :weapon_id => @weapon.id, :investigator_id => @investigator.id ).send(:valid_purchase?)
    
    @investigator.update_attribute( :funds, (@weapon.price + 1) )
    assert_equal true, Armament.new( :weapon_id => @weapon.id, :investigator_id => @investigator.id ).send(:valid_purchase?)
  end
  
  test 'validates weapon and investigator' do
    armament = Armament.new
    assert !armament.valid?
    assert armament.errors[:weapon_id].include?("is not a number")
    assert armament.errors[:investigator_id].include?("is not a number")
  end
  
  test 'validates uniqueness' do
    existing = armaments(:aleph_colt_45_automatic)
    armament = Armament.new(:investigator_id => existing.investigator_id, :weapon_id => existing.weapon_id)
    assert !armament.valid?
    assert armament.errors[:weapon_id].include?("has already been taken")
  end  
  
  test 'validates origin' do
    armament = Armament.create
    assert armament.errors[:origin].blank?, "blank origin should be ignored"
    
    armament = Armament.create(:origin => 'invalid')
    assert armament.errors[:origin].include?('is not included in the list')
  end
  
  test 'validates origin_valid' do
    @investigator.update_attribute( :funds, (@weapon.price - 1) )
    armament = Armament.create( :weapon_id => @weapon.id, :investigator_id => @investigator.id, :origin => 'purchase' )
    assert armament.errors[:investigator_id].include?('lacking funds')
  end
end