require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @character = characters(:thomas_malone)
    @contact = contacts(:aleph_thomas_malone)
  end
  
  test 'set_name' do
    @investigator.contacts.destroy_all
    contact = @investigator.contacts.create(:character_id => @character.id)
    assert_equal @character.name, contact.name, "contact should inherit character name"
  end
  
  test 'set_favor_count' do
    contact = @investigator.contacts.create
    assert_equal 0, contact.favor_count
  end  
  
  test 'use_favor!' do
    assert_difference '@contact.favor_count', -1 do
      @contact.use_favor!
    end
    assert_no_difference '@contact.favor_count' do
      assert_equal 0, @contact.favor_count
      assert_equal false, @contact.use_favor!
    end
  end
  
  test 'validates character and investigator' do
    contact = Contact.new
    assert !contact.valid?
    assert contact.errors[:character_id].include?("is not a number")
    assert contact.errors[:investigator_id].include?("is not a number")
  end  
  
  test 'entreatable?' do
    assert_equal true, @contact.entreatable?
    @contact.last_entreated_at = Time.now - 25.hours
    assert_equal true, @contact.entreatable?
    @contact.last_entreated_at = Time.now - 23.hours
    assert_equal false, @contact.entreatable?
  end
  
  test 'located?' do
    assert_not_equal @contact.character.location_id, @contact.investigator.location_id
    assert_equal false, @contact.located?
    @contact.investigator.update_attribute(:location_id, @contact.character.location_id)
    assert_equal true, @contact.located?
  end
  
  test 'entreat_favor!' do
    flexmock(@contact).should_receive(:entreatable?).and_return(true).once
    flexmock(@contact).should_receive(:located?).and_return(true).once
    assert_difference '@contact.favor_count', +1 do
      flexmock(@contact).should_receive(:log_entreat).once
      assert_equal true, @contact.entreat_favor!
      assert_not_nil @contact.last_entreated_at
    end
  end
  
  test 'entreat_favor! entreatable failure' do
    flexmock(@contact).should_receive(:entreatable?).and_return(false).once
    assert_no_difference '@contact.favor_count' do
      assert_equal false, @contact.entreat_favor!
    end
  end
  
  test 'entreat_favor! located failure' do
    flexmock(@contact).should_receive(:located?).and_return(false).once
    assert_no_difference '@contact.favor_count' do
      assert_equal false, @contact.entreat_favor!
    end
  end
  
  test 'log_entreat' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @contact.send(:log_entreat)
  end
  
  test 'percent_before_entreatable' do
    assert_equal 100, @contact.percent_before_entreatable
    
    @contact.last_entreated_at = Time.now - 24.hours
    assert_equal 100, @contact.percent_before_entreatable
    
    @contact.last_entreated_at = Time.now - 12.hours
    assert_equal 50, @contact.percent_before_entreatable
    
    @contact.last_entreated_at = Time.now
    assert_equal 0, @contact.percent_before_entreatable
  end  
  
end