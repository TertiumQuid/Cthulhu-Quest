require 'test_helper'

class AllyTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @ally = investigators(:gimel_pi)
    @character = characters(:thomas_malone)
  end
  
  test 'validates associations' do
    ally = Ally.new
    assert !ally.valid?
    assert ally.errors[:investigator_id].include?("is not a number")
    assert ally.errors[:ally_id].include?("is not a number")
  end

  test 'need_introduction_for ally' do
    @ally = investigators(:beth_pi)
    @ally.contacts.destroy_all
    assert @investigator.inner_circle.include?( @ally )
    assert @investigator.allies.need_introduction_for( @character.id ).map(&:ally).include?( @ally )
  end

  test 'without_contact_for' do
    @ally = investigators(:beth_pi)
    assert @investigator.inner_circle.include?( @ally )
    assert !@investigator.allies.without_contact_for( @character.id ).map(&:ally).include?( @ally )
  end
  
  test 'need_introduction_for non ally' do
    assert !@investigator.inner_circle.include?( @ally )
    assert !@investigator.allies.need_introduction_for( @character.id ).map(&:ally).include?( @ally )
  end  
    
  test 'validates uniqueness' do
    existing = allies(:aleph_beth)
    ally = Ally.new(:investigator_id => existing.investigator_id, :ally_id => existing.ally_id)
    assert !ally.valid?
    assert ally.errors[:ally_id].include?("has already been taken")
  end  
  
  test 'validates cannot_ally_oneself' do
    ally = Ally.new(:investigator_id => @investigator.id, :ally_id => @investigator.id)
    assert !ally.valid?
    assert ally.errors[:ally_id].include?("cannot be self")
  end  
  
  test 'set_name' do
    investigator = investigators(:aleph_pi)
    allied = investigators(:gimel_pi)
    ally = investigator.allies.create(:ally_id => allied.id)
    assert_equal allied.name, ally.name
  end  
  
  test 'log_alliance' do
    ally = Ally.new
    flexmock(InvestigatorActivity).should_receive(:log).twice
    ally.send(:log_alliance)
  end  
  
  test 'log_alliance on create' do
    existing = allies(:aleph_beth)
    ally = Ally.new(:investigator_id => existing.investigator_id, :ally_id => existing.ally_id)
    existing.destroy
    flexmock(ally).should_receive(:log_alliance).once
    ally.save!
  end
end