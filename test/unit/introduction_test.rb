require 'test_helper'

class IntroductionTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:gimel_pi)
    @introducer = investigators(:aleph_pi)
    @contact = contacts(:aleph_thomas_malone)
    @character = characters(:thomas_malone)
    @introduction = introductions(:gimel_robert_blake_aleph)
  end
  
  def create_introduction(investigator_id=nil,introducer_id=nil)
    @contact.update_attribute(:favor_count, 3)
    investigators(:aleph_pi).update_attribute(:location_id, @character.location_id)
    @introduction = Introduction.new(:character_id => characters(:thomas_malone).id, :introducer_id => (introducer_id || @investigator.id), :investigator_id => (investigator_id || @introducer.id), :message => 'test', :status => 'arranged')
    @introduction.save(:validate => false)
  end
  
  test 'create from plot' do
    plot = plots(:hellfire_club)
    
    intro = Introduction.new(:character_id => @character.id, :plot_id => plot.id, :investigator_id => @investigator.id, :message => 'test')
    flexmock(intro).should_receive(:set_message).once
    flexmock(intro).should_receive(:validates_no_contact).once
    flexmock(intro).should_receive(:validates_introducer_favors).once
    flexmock(intro).should_receive(:validates_one_introduction_per_day).once
    flexmock(intro).should_receive(:validates_introducer_location).once
    flexmock(intro).should_receive(:use_favors).once    
    flexmock(intro).should_receive(:log_introduction).once
    assert_difference 'Introduction.count', +1 do
      assert intro.save!
      assert_equal plot, intro.plot
    end
    intro.save    
  end
      
  test 'create from introducer' do
    @contact.update_attribute(:favor_count, Introduction::COST)
    
    intro = Introduction.new(:character_id => @character.id, :introducer_id => @introducer.id, :investigator_id => @investigator.id, :message => 'test')
    flexmock(intro).should_receive(:set_message).once
    flexmock(intro).should_receive(:validates_no_contact).once
    flexmock(intro).should_receive(:validates_introducer_favors).once
    flexmock(intro).should_receive(:validates_one_introduction_per_day).once
    flexmock(intro).should_receive(:validates_introducer_location).once
    flexmock(intro).should_receive(:use_favors).once    
    flexmock(intro).should_receive(:log_introduction).once
    assert_difference 'Introduction.count', +1 do
      assert intro.save!
      assert_equal @introducer, intro.introducer
    end
    intro.save
  end
  
  test 'arranged?' do
    intro = Introduction.new(:status => 'arranged')
    assert_equal true, intro.arranged?
    intro.status = 'accepted'
    assert_equal false, intro.arranged?
  end
  
  test 'introduced?' do
    intro = Introduction.new(:introducer_id => @introducer.id)
    assert_equal true, intro.introduced?
    intro.introducer_id = nil
    assert_equal false, intro.introduced?
  end  
  
  test 'reward_introducer' do  
    assert_difference '@introduction.introducer.reload.experience', +Introduction::COST do
      @introduction.send(:reward_introducer)
    end
  end
  
  test 'reward_investigator' do  
    assert_difference '@introduction.investigator.reload.contacts.count', +1 do
      @introduction.send(:reward_investigator)
    end    
    assert @introduction.investigator.contacts.map(&:character).include?(@introduction.character)
  end
  
  test 'punish_introducer' do  
    contact = contacts(:gimel_robert_blake)
    favors = contact.favor_count
    assert_difference 'contact.reload.favor_count', -favors do
      @introduction.send(:punish_introducer)
    end
  end
  
  test 'accept!' do
    flexmock(@introduction).should_receive(:reward_introducer).once
    flexmock(@introduction).should_receive(:reward_investigator).once
    assert_equal true, @introduction.accept!
    assert_equal 'accepted', @introduction.reload.status
  end
  
  test 'accept! without introducer' do
    @introduction.update_attribute(:introducer_id,nil)
    @introduction.update_attribute(:plot_id,plots(:hellfire_club).id)
    flexmock(@introduction).should_receive(:award_experience!).times(0)
   assert_equal true, @introduction.accept!
    assert_equal 'accepted', @introduction.reload.status
  end  
  
  test 'accept! not arranged' do  
    @introduction.update_attribute(:status,'dismissed')
    flexmock(@introduction).should_receive(:update_attribute).times(0)
    assert_equal false, @introduction.accept!
    assert @introduction.errors[:base].include?("introduction not arranged")
    assert_equal 'dismissed', @introduction.reload.status
  end
  
  test 'accept! not located' do
    @introduction.investigator.update_attribute(:location_id, locations(:rome).id)
    flexmock(@introduction).should_receive(:update_attribute).times(0)
    assert_equal false, @introduction.accept!
    assert @introduction.errors[:base].include?("investigator must be at character's location")
    assert_equal 'arranged', @introduction.reload.status
  end
  
  test 'validates investigator and character' do
    intro = Introduction.new
    assert !intro.valid?
    assert intro.errors['investigator_id'].include?("is not a number")
    assert intro.errors['character_id'].include?("is not a number")
  end  
  
  test 'validates_introducer_or_plot' do  
    intro = Introduction.new
    assert !intro.valid?
    assert intro.errors['base'].include?("must be acquired through an investigator or plot")
  end
  
  test 'set_message for introducer' do
    intro = Introduction.new(:introducer => @introducer, :character => @contact.character)
    intro.send(:set_message)
    assert_not_nil intro.message
  end
  
  test 'set_message for plot' do
    plot = plots(:zohar)
    intro = Introduction.new(:plot => plot, :character => @contact.character)
    intro.send(:set_message)
    assert_not_nil intro.message
  end  
  
  test 'validates_no_contact' do
    intro = Introduction.create(:investigator_id => @contact.investigator_id, :character_id => @contact.character_id)
    assert intro.errors['investigator_id'].include?("already has contact")
  end
  
  test 'validates_introducer_favors' do
    @contact.update_attribute(:favor_count, Introduction::COST - 1)
    intro = Introduction.new(:character_id => @contact.character_id, :introducer_id => @introducer.id)
    intro.send(:validates_introducer_favors)
    assert intro.errors[:character_id].include?("does not have enough favors")
  end
  
  test 'validates_one_introduction_per_day' do
    @contact.update_attribute(:favor_count, 10)
    @introducer.update_attribute(:location_id, @character.location_id)
    Introduction.create(:character_id => @character.id, :introducer_id => @introducer.id, :investigator_id => @investigator.id)
    intro = Introduction.create(:character_id => @character.id, :introducer_id => @introducer.id, :investigator_id => @investigator.id)
    assert intro.errors[:introducer_id].include?("has already arranged one introduction today")
  end
  
  test 'validates_introducer_location' do
    @contact.update_attribute(:favor_count, Introduction::COST)
    intro = Introduction.create(:character_id => @character.id, :introducer_id => @introducer.id, :investigator_id => @investigator.id)
    assert intro.errors[:introducer_id].include?("cannot arrange an introduction unless in character location")
  end  
  
  test 'use_favors' do
    intro = Introduction.new(:character_id => @contact.character_id, :introducer_id => @introducer.id)
    assert_difference '@contact.reload.favor_count', -[Introduction::COST, @contact.favor_count].min do
      intro.send(:use_favors)
    end
  end
  
  test 'set_status' do
    intro = Introduction.new
    intro.send(:set_status)
    assert_equal 'arranged', intro.status
    flexmock(intro).should_receive(:set_status).once
    intro.save
  end
  
  test 'log_introduction' do
    intro = Introduction.new
    flexmock(InvestigatorActivity).should_receive(:log).twice
    intro.send(:log_introduction)
    intro.introducer_id = @introducer.id
    intro.send(:log_introduction)
  end  
  
  test 'located?' do
    intro = Introduction.new(:character_id => @character.id, :investigator_id => @investigator.id)    
    assert_equal false, intro.located?
    
    intro.investigator.update_attribute(:location_id, @character.location_id)
    assert_equal true, intro.located?
  end
end