require 'test_helper'

class GiftTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @ally = investigators(:gimel_pi)
    
    @funds = 1
    @funds_gift = @investigator.giftings.new(:investigator => @ally, :gifting => @funds)
    
    @possession = possessions(:aleph_lantern)
    @item_gift = @investigator.giftings.new(:investigator => @ally, :gifting => @possession.item_name)
    
    @armament = armaments(:aleph_colt_45_automatic)
    @weapon_gift = @investigator.giftings.new(:investigator => @ally, :gifting => @armament.weapon_name)
  end
  
  test 'set gifting blank' do
    gift = Gift.new(:gifting => nil)
    assert_nil gift.instance_variable_get('@gifting')
  end
  
  test 'set gifting funds' do
    assert_equal @funds, @funds_gift.instance_variable_get('@gifting')
    assert_equal @funds, @funds_gift.gift_id
    assert_equal 'funds', @funds_gift.gift_type
    assert_equal "£#{@funds}", @funds_gift.gift_name
  end
  
  test 'set gifting item' do  
    assert_equal @possession.item_name, @item_gift.instance_variable_get('@gifting')
    assert_equal @possession.item_id, @item_gift.gift_id
    assert_equal 'item', @item_gift.gift_type
    assert_equal @possession.item_name, @item_gift.gift_name
  end  

  test 'set gifting weapon' do  
    assert_equal @armament.weapon_name, @weapon_gift.instance_variable_get('@gifting')
    assert_equal @armament.weapon_id, @weapon_gift.gift_id
    assert_equal 'weapon', @weapon_gift.gift_type
    assert_equal @armament.weapon_name, @weapon_gift.gift_name
  end
  
  test 'get gifting blank' do
    assert_nil Gift.new.gifting
  end
  
  test 'get gifting funds' do
    assert_equal @funds, @funds_gift.gift_id
  end  
  
  test 'get gifting item' do
    assert_equal @possession.item, @item_gift.gifting
  end  
  
  test 'get gifting weapon' do
    assert_equal @armament.weapon, @weapon_gift.gifting
  end  
  
  test 'validates_investigators' do
    gift = Gift.create
    assert gift.errors[:investigator_id].include?('is missing')
    assert gift.errors[:sender_id].include?('is missing')
  end
  
  test 'validates gift attributes' do
    gift = Gift.create
    assert gift.errors[:gift_id].include?('is missing')
    assert gift.errors[:gift_name].include?("is missing")
    assert gift.errors[:gift_type].include?("is not allowed")
  end
  
  test 'funds_value?' do
    gift = Gift.new
    
    assert_equal false, gift.send(:funds_value?, nil)
    assert_equal false, gift.send(:funds_value?, @possession.item_name)
    assert_equal true, gift.send(:funds_value?, 1)
    assert_equal true, gift.send(:funds_value?, '1')
  end
  
  test 'item?' do
    gift = Gift.new
    assert_equal false, gift.item?
    gift.gift_type = 'weapon'
    assert_equal false, gift.item?
    gift.gift_type = 'item'
    assert_equal true, gift.item?
  end  
  
  test 'weapon?' do
    gift = Gift.new
    assert_equal false, gift.weapon?
    gift.gift_type = 'item'
    assert_equal false, gift.weapon?
    gift.gift_type = 'weapon'
    assert_equal true, gift.weapon?
  end  
  
  test 'funds?' do
    gift = Gift.new
    assert_equal false, gift.funds?
    gift.gift_type = 'item'
    assert_equal false, gift.funds?
    gift.gift_type = 'funds'
    assert_equal true, gift.funds?
  end
  
  test 'set_sender_name on create' do
    assert @funds_gift.save
    assert_equal @funds_gift.sender.name, @funds_gift.sender_name
  end  
  
  test 'validates_ownership for funds' do
    gift = Gift.new
    flexmock(gift).should_receive(:funds?).and_return(true).once
    flexmock(gift).should_receive(:validate_funds).and_return(true).once
    assert_equal true, gift.send(:validates_ownership)
  end
  
  test 'validates_ownership for item' do 
    gift = Gift.new     
    flexmock(gift).should_receive(:item?).and_return(true).once
    flexmock(gift).should_receive(:validate_item).and_return(true).once
    assert_equal true, gift.send(:validates_ownership)
  end
  
  test 'validates_ownership for weapon' do  
    gift = Gift.new
    flexmock(gift).should_receive(:weapon?).and_return(true).once
    flexmock(gift).should_receive(:validate_weapon).and_return(true).once
    assert_equal true, gift.send(:validates_ownership)    
  end

  test 'validate_funds' do
    @funds_gift.gifting = 10000
    @funds_gift.send(:validate_funds)
    assert @funds_gift.errors[:base].include?('insufficient funds at your disposal for such a generous gift')
  end

  test 'validate_item' do
    @item_gift.gift_id = nil
    @item_gift.send(:validate_item)
    assert @item_gift.errors[:base].include?("you don't possess an item by that name")
  end
  
  test 'validate_weapon' do
    @weapon_gift.gift_id = nil
    @weapon_gift.send(:validate_weapon)
    assert @weapon_gift.errors[:base].include?("you don't possess a weapon by that name")
  end  
  
  test 'send_gift on create' do
    flexmock(@funds_gift).should_receive(:send_gift).and_return(true).once
    assert @funds_gift.save
    @funds_gift.save
  end
  
  test 'send_gift funds' do
    gift = Gift.new
    flexmock(gift).should_receive(:funds?).and_return(true).once
    flexmock(gift).should_receive(:send_funds).and_return(true).once
    assert_equal true, gift.send(:send_gift)
  end
  
  test 'send_gift item' do 
    gift = Gift.new     
    flexmock(gift).should_receive(:item?).and_return(true).once
    flexmock(gift).should_receive(:send_item).and_return(true).once
    assert_equal true, gift.send(:send_gift)
  end
  
  test 'send_gift weapon' do  
    gift = Gift.new
    flexmock(gift).should_receive(:weapon?).and_return(true).once
    flexmock(gift).should_receive(:send_weapon).and_return(true).once
    assert_equal true, gift.send(:send_gift)    
  end
    
 test 'send_funds' do
    assert_difference '@funds_gift.investigator.funds', +@funds_gift.gift_id do
      assert_difference '@funds_gift.sender.funds', -@funds_gift.gift_id do
        @funds_gift.send(:send_funds)
      end
    end
  end
  
  test 'send_item' do
    assert_difference '@item_gift.investigator.possessions.count', +1 do
      assert_difference '@item_gift.sender.possessions.count', -1 do
        @item_gift.send(:send_item)
      end
    end
  end  
  
  test 'send_weapon' do
    assert_difference '@weapon_gift.investigator.armaments.count', +1 do
      assert_difference '@weapon_gift.sender.armaments.count', -1 do
        @weapon_gift.send(:send_weapon)
      end
    end
    assert_nil @weapon_gift.sender.armed
  end  
  
  test 'log_gift on create' do
    flexmock(@funds_gift).should_receive(:log_gift).and_return(true).once
    assert @funds_gift.save
    @funds_gift.save
  end

  test 'log_gift for funds' do
    assert_difference 'InvestigatorActivity.count', +2 do
      @funds_gift.send(:log_gift)
    end
  end
  
  test 'log_gift for item' do
    assert_difference 'InvestigatorActivity.count', +2 do
      @item_gift.send(:log_gift)
    end
  end  
  
  test 'log_gift for weapon' do
    assert_difference 'InvestigatorActivity.count', +2 do
      @weapon_gift.send(:log_gift)
    end
  end  
end
