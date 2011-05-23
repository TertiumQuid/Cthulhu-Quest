require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  def setup
    @item = items(:timepiece)
  end
  
  test 'activatable?' do
    @item.kind = 'artifact'
    assert_equal true, @item.activatable?
    
    ['equipment','book','medical'].each do |k|
      @item.kind = k
      assert_equal false, @item.activatable?
    end
  end
  
  test 'medical?' do
    @item.kind = 'medical'
    assert_equal true, @item.medical?
    
    ['equipment','book','artifact','spirit'].each do |k|
      @item.kind = k
      assert_equal false, @item.medical?
    end
  end 
  
  test 'euipment?' do
    @item.kind = 'equipment'
    assert_equal true, @item.equipment?
    
    ['medical','book','artifact','spirit'].each do |k|
      @item.kind = k
      assert_equal false, @item.equipment?
    end
  end
    
  test 'book?' do
    @item.kind = 'book'
    assert_equal true, @item.book?
    
    ['equipment','medical','artifact','spirit'].each do |k|
      @item.kind = k
      assert_equal false, @item.book?
    end
  end  
  
  test 'spirit?' do
    @item.kind = 'spirit'
    assert_equal true, @item.spirit?
    
    ['equipment','medical','artifact','book'].each do |k|
      @item.kind = k
      assert_equal false, @item.spirit?
    end
  end   
  
  test 'effect_names' do
    item = items(:abramelin_oil)
    assert !item.effects.blank?
    names = item.effects.map(&:name).join(', ')
    assert_equal names, item.effect_names
  end
end