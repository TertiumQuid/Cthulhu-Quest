require 'test_helper'

class GuestTest < ActiveSupport::TestCase
  def setup
    @guest = guests(:aleph_beth_estate_auction)
  end
  
  test 'validates unique guest' do
    guest = Guest.create(:social => @guest.social, :investigator_id => @guest.investigator.id)
    assert guest.errors[:investigator_id].include?("has already been taken")
  end
  
  test 'validates status' do
    guest = Guest.create
    assert guest.errors[:status].include?("is not included in the list")
    guest = Guest.create(:status => 'bad')
    assert guest.errors[:status].include?("is not included in the list")
  end
  
  test 'validates_ally' do
    Ally.destroy_all
    guest = Guest.create(:social => @guest.social, :investigator_id => @guest.investigator.id)
    assert guest.errors[:investigator_id].include?("not allied with the host")
  end
  
  test 'cooperated?' do
    @guest.status = 'defected'
    assert_equal false, @guest.cooperated?
    @guest.status = 'cooperated'
    assert_equal true, @guest.cooperated?
  end
  
  test 'defected?' do
    @guest.status = 'defected'
    assert_equal true, @guest.defected?
    @guest.status = 'cooperated'
    assert_equal false, @guest.defected?
  end  
  
  test 'description' do
    @guest.status = 'defected'
    assert_equal @guest.social.social_function.defection, @guest.description
    @guest.status = 'cooperated'
    assert_equal @guest.social.social_function.cooperation, @guest.description
  end
  
  test 'log_rsvp' do
    flexmock(InvestigatorActivity).should_receive(:log).twice
    @guest.send(:log_rsvp)
  end  
  
  test 'log_rsvp on create' do
    guest = Guest.new(:social => @guest.social, :investigator_id => investigators(:gimel_pi).id, :status => 'cooperated')
    flexmock(guest).should_receive(:log_rsvp).once
    guest.save!
  end
end