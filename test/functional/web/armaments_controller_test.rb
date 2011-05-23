require 'test_helper'

class Web::ArmamentsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @weapon = weapons(:remington_double_derringer)
    flexmock(@controller).should_receive(:award_daily_income)
  end

  test 'purchase' do
    @user.investigator.update_attribute(:funds, @weapon.price)
    @controller.login!(@user)
    
    assert_difference ['Armament.count'], +1 do
      post :purchase, :id => @weapon.id
      assert_response :found
      assert !assigns(:armament).blank?
      assert !assigns(:weapon).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_weapons_path
    end
  end
  
  test 'purchase failure' do
    @user.investigator.update_attribute(:funds, @weapon.price - 1)
    @controller.login!(@user)
    
    assert_no_difference ['Armament.count'] do
      post :purchase, :id => @weapon.id
      assert_response :found
      assert !assigns(:weapon).blank?
      assert !assigns(:armament).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_weapons_path
    end
  end  
      
  test 'equip' do
    armament = armaments(:aleph_colt_45_automatic)
    @controller.login!(@user)
    put :update, :id => armament.id
    assert_response :found
    assert !flash[:notice].blank?
    assert_equal armament.id, @user.investigator.armed.id
    assert_redirected_to edit_web_investigator_path
  end
  
  test 'require_user' do
    post :purchase, :id => 1
    assert_user_required
    
    put :update, :id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    post :purchase, :id => 1
    assert_investigator_required
    
    put :update, :id => 1
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/web/armaments/1/purchase"}, 
                   {:controller => 'web/armaments', :action => 'purchase', :id => '1' })
    assert_routing({:method => 'put', :path => "/web/armaments/1"}, 
                   {:controller => 'web/armaments', :action => 'update', :id => '1' })
  end  
end