require 'test_helper'

class Facebook::ArmamentsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @weapon = weapons(:remington_double_derringer)
    @armament = armaments(:aleph_colt_45_automatic)
    flexmock(@controller).should_receive(:award_daily_income)
    init_signed_request
  end
  
  test 'update' do
    @user.investigator.update_attribute(:armed_id, nil)
    put :update, :id => @armament.id, :signed_request => @signed_request
    assert_response :found
    assert !flash[:notice].blank?
    assert_equal @armament.id, @user.investigator.reload.armed.id
    assert_redirected_to facebook_items_path
  end  
  
  test 'update for js' do
    @user.investigator.update_attribute(:armed_id, nil)
    put :update, :id => @armament.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['message'].blank?
  end  

  test 'purchase' do
    @user.investigator.update_attribute(:funds, @weapon.price)
    
    assert_difference ['Armament.count','@user.investigator.armaments.count'], +1 do
      post :purchase, :id => @weapon.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:weapon).blank?
      assert !assigns(:armament).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_items_path
    end
  end 
  
  test 'purchase js' do
    @user.investigator.update_attribute(:funds, @weapon.price)
    
    assert_difference ['Armament.count','@user.investigator.armaments.count'], +1 do
      post :purchase, :id => @weapon.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:weapon).blank?
      assert !assigns(:armament).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end   
  
  test 'purchase failure' do
    @user.investigator.update_attribute(:funds, @weapon.price - 1)
    
    assert_no_difference ['Possession.count'] do
      post :purchase, :id => @weapon.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:weapon).blank?
      assert !assigns(:armament).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_items_path
    end
  end  
  
  test 'purchase failure for js' do
    @user.investigator.update_attribute(:funds, @weapon.price - 1)
    
    assert_no_difference ['Possession.count'] do
      post :purchase, :id => @weapon.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:weapon).blank?
      assert !assigns(:armament).blank?
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end
  
  test 'armed_message' do
    @controller.instance_variable_set( '@armament', @armament )
    expected = "#{@armament.weapon_name} armed and readied."
    assert_equal expected, @controller.send(:armed_message)
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@weapon', @weapon )
    expected = "Purchased #{@weapon.name} for £#{@weapon.price}"
    assert_equal expected, @controller.send(:success_message)
  end  

  test 'failure_message' do
    @armament.errors[:base] << 'test1'
    @armament.errors[:base] << 'test2'
    @controller.instance_variable_set( '@armament', @armament )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'return_path' do
    assert_equal facebook_items_path, @controller.send(:return_path)
  end  
  
  test 'require_user' do
    put :update, :id => 1
    assert_user_required
        
    post :purchase, :id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy

    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required
  
    post :purchase, :id => 1, :signed_request => @signed_request
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/facebook/armaments/1"}, 
                   {:controller => 'facebook/armaments', :action => 'update', :id => '1' })    
    assert_routing({:method => 'post', :path => "/facebook/armaments/1/purchase"}, 
                   {:controller => 'facebook/armaments', :action => 'purchase', :id => '1' })
  end  
end