require 'test_helper'

class PossessionTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @ally = investigators(:beth_pi)
    @item = items(:timepiece)
    @possession = possessions(:aleph_lantern)
    @medical = possessions(:aleph_first_aid_kit)
    @spirit = possessions(:aleph_dark_rum)
    @book = possessions(:aleph_the_zohar)
  end
  
  test 'set_item_name' do
    possession = @investigator.possessions.create(:item_id => @item.id)
    assert_equal @item.name, possession.item_name, "possession should inherit item name"
  end  
  
  test 'set_uses_count' do
    possession = @investigator.possessions.create(:item_id => @item.id)
    assert_equal @item.uses_count, possession.uses_count, "possession should inherit item uses count"
  end  
  
  test 'studyable?' do
    assert_nil @book.last_used_at
    assert_equal true, @book.studyable?
    
    @book.update_attribute(:last_used_at, Time.now - Item::STUDY_TIMEFRAME.hours - 1.minute)
    assert_equal true, @book.studyable?
    
    @book.update_attribute(:last_used_at, Time.now - Item::STUDY_TIMEFRAME.hours + 1.minute)
    assert_equal false, @book.studyable?
  end

  test 'primed?' do
    assert_nil @book.last_used_at
    assert_equal true, @book.primed?

    @book.update_attribute(:last_used_at, Time.now - Item::ACTIVATION_TIMEFRAME.hours + 1.hour)
    assert_equal false, @book.item.activatable?
    assert_equal false, @book.primed?

    @book.update_attribute(:item_id, items(:rod_of_asclepius).id )
    @book.update_attribute(:last_used_at, Time.now - Item::ACTIVATION_TIMEFRAME.hours + 1.hours)
    @book.reload
    
    assert_equal true, @book.item.activatable?
    assert_equal false, @book.primed?
    
    @book.update_attribute(:last_used_at, Time.now - Item::ACTIVATION_TIMEFRAME.hours - 1.minute)
    assert_equal true, @book.primed?
  end
  
  test 'usable?' do
    assert_equal true, @possession.usable?
    @possession.uses_count = 0
    assert_equal true, @possession.usable?
    @possession.uses_count = nil
    assert_equal false, @possession.usable?
  end
  
  test 'used?' do  
    assert_equal false, @possession.used?
    @possession.uses_count = nil
    assert_equal false, @possession.used?
    @possession.uses_count = 0
    assert_equal true, @possession.used?
  end
  
  test 'use!' do  
    timestamp = Time.now
    flexmock(Time).should_receive(:now).and_return(timestamp)
    flexmock(@possession).should_receive(:create_effects).once
    flexmock(@possession).should_receive(:use_medicine).times(0)
    @possession.update_attribute(:uses_count, 2)
    
    assert_no_difference 'Possession.count' do
      assert_difference '@possession.uses_count', -1 do
        @possession.use!
        @possession.reload
        assert_equal timestamp.to_i, @possession.last_used_at.to_i
      end
    end
  end
  
  test 'use! medical' do 
    flexmock(@medical).should_receive(:use_medicine).once
    @medical.use!
  end  
  
  test 'use! book' do  
    flexmock(@book).should_receive(:study_book).and_return(true).once
    flexmock(@book).should_receive(:create_effects).times(0)
    assert_equal true, @book.use!
  end
  
  test 'use! and destroy' do  
    @possession.update_attribute(:uses_count, 1)
    assert_difference ['Possession.count'], -1 do
      @possession.use!
    end
  end  
  
  test 'use! ignored' do
    flexmock(@possession).should_receive(:usable?).and_return(false)
    assert_no_difference ['@possession.uses_count','Possession.count'] do
      assert_nil @possession.use!
      assert_nil @possession.last_used_at
    end
  end
  
  test 'use! with cooldown' do
    possession = possessions(:aleph_abramelin_oil)
    possession.update_attribute(:last_used_at, Time.now - 1.minute)
    assert_no_difference ['possession.uses_count','Possession.count'] do     
      assert_nil possession.use!
    end
  end
  
  test 'origin' do
    origin = 'purchase'
    possession = Possession.new( :origin => origin )
    assert_equal origin, possession.origin, "origin should be attr_accessor"
  end
  
  test 'validates item_name' do
    possession = Possession.new
    assert !possession.valid?
    assert possession.errors[:item_name].include?("can't be blank")
  end  
  
  test 'valid_purchase?' do
    assert_nil Possession.new.send(:valid_purchase?)
    assert_nil Possession.new( :item_id => @item.id ).send(:valid_purchase?)
    
    @investigator.update_attribute( :funds, (@item.price - 1) )
    assert_equal false, Possession.new( :item_id => @item.id, :investigator_id => @investigator.id ).send(:valid_purchase?)
    
    @investigator.update_attribute( :funds, (@item.price + 1) )
    assert_equal true, Possession.new( :item_id => @item.id, :investigator_id => @investigator.id ).send(:valid_purchase?)
  end
  
  test 'validates item and investigator' do
    possession = Possession.new
    assert !possession.valid?
    assert possession.errors[:item_id].include?("can't be blank")
    assert possession.errors[:item_id].include?("is not a number")
    assert possession.errors[:investigator_id].include?("can't be blank")
    assert possession.errors[:investigator_id].include?("is not a number")
  end
  
  test 'validates origin' do
    possession = Possession.create
    assert possession.errors[:origin].blank?, "blank origin should be ignored"
    
    possession = Possession.create(:origin => 'invalid')
    assert possession.errors[:origin].include?('is not included in the list')
  end
  
  test 'validates funds' do
    @investigator.update_attribute( :funds, (@item.price - 1) )
    possession = Possession.create( :item_id => @item.id, :investigator_id => @investigator.id, :origin => 'purchase' )
    assert possession.errors[:investigator_id].include?('lacking funds')
  end
  
  test 'cooldown_valid? false' do
    possession = possessions(:aleph_abramelin_oil)
    possession.update_attribute(:last_used_at, Time.now - 1.minute)
    assert_equal false, possession.send(:cooldown_valid?)
    assert possession.errors[:base].include?("still recharging from last use")
  end

  test 'cooldown_valid? true' do
    possession = possessions(:aleph_abramelin_oil)
    possession.update_attribute(:last_used_at, Time.now - 1.day)
    assert_equal true, possession.send(:cooldown_valid?)
  end
  
  test 'cooldown_finished' do
    possession = possessions(:aleph_abramelin_oil)
    possession.update_attribute(:last_used_at, nil)
    assert_equal true, possession.send(:cooldown_finished?, 1)
    
    possession.update_attribute(:last_used_at, Time.now - 1.day)
    assert_equal true, possession.send(:cooldown_finished?, 23)
    
    possession.update_attribute(:last_used_at, Time.now)
    assert_equal false, possession.send(:cooldown_finished?, 1)    
  end
  
  test 'uniqueness_valid on create' do
    possession = @investigator.possessions.new(:origin => 'gift') 
    flexmock(possession).should_receive(:uniqueness_valid).once
    possession.save
  end
  
  test 'uniqueness_valid' do  
    possession = possessions(:aleph_the_zohar)
    book = @investigator.possessions.create(:origin => 'gift', :item => possession.item)
    assert book.item.book?
    assert book.errors[:item_id].include?("already possessed")
  end  
  
  test 'create_effects' do
    possession = possessions(:aleph_abramelin_oil)
    
    assert possession.item.activatable?
    assert_difference ['possession.investigator.reload.effections.count'], +possession.item.effects.count do
      possession.send(:create_effects)
    end
  end
  
  test 'create_effects ignored for not activatable' do
    possession = possessions(:aleph_abramelin_oil)
    possession.item.kind = 'equipment'
    
    assert !possession.item.activatable? 
    assert_no_difference ['Effection.count'] do
      possession.send(:create_effects)
    end
  end
  
  test 'targeting_self?' do
    assert_equal true, @possession.targeting_self?(nil)
    assert_equal true, @possession.targeting_self?( @investigator )
    assert_equal false, @possession.targeting_self?( @ally )
  end
  
  test 'use_medicine for self' do
    @medical.investigator.update_attribute(:wounds, @medical.item.power + 1)
    flexmock(@medical).should_receive(:log_medical_treatment).once
    flexmock(Investigator).new_instances.should_receive(:healing_effect_bonus).once
    
    assert_difference '@medical.investigator.wounds', -@medical.item.power do
      @medical.send(:use_medicine)
    end
  end
  
  test 'use_medicine for another' do
    @medical.investigator.update_attribute(:wounds, @medical.item.power + 1)
    @ally.update_attribute(:wounds, @medical.item.power + 1)
    flexmock(@medical).should_receive(:log_medical_treatment).with(@ally).once
    flexmock(Investigator).new_instances.should_receive(:healing_effect_bonus).times(2)
    
    assert_difference ['@medical.investigator.wounds','@ally.wounds'], -@medical.item.power do
      @medical.send(:use_medicine, @ally)
    end
  end
  
  test 'use_spirit for self' do
    @spirit.investigator.update_attribute(:madness, @spirit.item.power + 1)
    flexmock(@spirit).should_receive(:log_spirit_drunken).once
    
    assert_difference '@spirit.investigator.madness', -@spirit.item.power do
      @spirit.send(:use_spirit)
    end
  end  
  
  test 'use_spirit for another' do
    @spirit.investigator.update_attribute(:madness, @spirit.item.power + 1)
    @ally.update_attribute(:madness, @spirit.item.power + 1)
    flexmock(@spirit).should_receive(:log_spirit_drunken).with(@ally).once
    
    assert_difference ['@spirit.investigator.madness','@ally.madness'], -@spirit.item.power do
      @spirit.send(:use_spirit, @ally)
    end
  end
    
  test 'log_medical_treatment for self' do
    assert_difference 'InvestigatorActivity.count', +1 do
      @possession.send(:log_medical_treatment, nil)
    end
  end  
  
  test 'log_medical_treatment for other' do
    assert_difference 'InvestigatorActivity.count', +3 do
      @possession.send(:log_medical_treatment, @ally)
    end
  end  
  
  test 'log_purchase' do
    purchase = @investigator.possessions.new(:item => @item, :origin => 'purchase')
    mock = flexmock(InvestigatorActivity)
    mock.should_receive(:log).once.with(@investigator, 'item.purchased', {:subject => @item})
    
    purchase.send(:log_purchase)
  end  
  
  test 'log_purchase on create' do
    @investigator.update_attribute(:funds, @item.price)
    purchase = @investigator.possessions.new(:item => @item, :origin => 'purchase')
    flexmock(purchase).should_receive(:log_purchase).once
    purchase.save!
  end  
  
  test 'log_purchase ignored unless purchase' do
    purchase = @investigator.possessions.new(:item => @item, :origin => 'gift')
    flexmock(InvestigatorActivity).should_receive(:log).times(0)
    purchase.send(:log_purchase)
  end

  test 'study_book' do
    assert_difference ['@book.uses_count'], -1 do
      assert_difference ['@book.investigator.moxie'], +1 do
        assert_equal true, @book.send(:study_book), @book.errors.inspect
        assert_not_nil @book.last_used_at
      end
    end
  end
  
  test 'study_book failure with last_used_at' do
    @book.update_attribute(:last_used_at, (Time.now - Item::STUDY_TIMEFRAME.hours + 1.minute) )
    assert_equal false, @book.send(:study_book)
    assert @book.errors[:base].include?("you are still studying this book right now")
  end
  
  test 'study_book failure with uses_count' do
    @book.update_attribute(:uses_count, 0)
    assert_equal false, @book.send(:study_book)
    assert @book.errors[:base].include?("you have already studied this book in full")
  end  
  
  test 'remaining_study_time_in_percent' do
    @book.last_used_at = Time.now
    assert_equal 100, @book.remaining_study_time_in_percent
    
    @book.last_used_at = Time.now - (Item::STUDY_TIMEFRAME / 2).hours
    assert_equal 50, @book.remaining_study_time_in_percent
    
    @book.last_used_at = Time.now - Item::STUDY_TIMEFRAME.hours
    assert_equal 0, @book.remaining_study_time_in_percent
  end  
  
end