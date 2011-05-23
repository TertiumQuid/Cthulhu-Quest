require 'test_helper'

class Web::LocationsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @location = locations(:new_york)
    @transit = transits(:arkham_new_york)
    flexmock(@controller).should_receive(:award_daily_income)
  end
  
  test 'show' do
    @controller.login!(@user)
    
    get :show, :id => @location.id
    assert_response :success
    assert_template "web/locations/show"
    assert !assigns(:location).blank?
    assert !assigns(:transits).blank?
    assert !assigns(:denizens).blank?
    assert !assigns(:characters).blank?
    assert !assigns(:plots).blank?
    assigns(:characters).each do |character|
      assert_tag :tag => "a", :attributes => { :href => web_character_path(character) }
    end
  end
  
  test 'update' do
    @controller.login!(@user)
    
    assert_difference '@investigator.funds', -@transit.price do
      put :update, :id => @location.id
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to web_location_path(@location)
      assert_equal @location, @investigator.reload.location
    end
  end
  
  test 'update failure' do
    @investigator.update_attribute(:funds, 0)
    @controller.login!(@user)
    arkham = locations(:arkham)
    
    put :update, :id => @location.id
    assert_response :found
    assert !flash[:error].blank?
    assert_redirected_to web_location_path(arkham)
    assert_equal arkham, @investigator.reload.location
  end
  
  test 'require_user' do
    get :show, :id => 1
    assert_user_required
    
    put :update, :id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    get :show, :id => 1
    assert_investigator_required
    
    put :update, :id => 1
    assert_investigator_required 
  end  
  
  test 'routes' do
    assert_routing("/web/locations", { :controller => 'web/locations', :action => 'index' })
    assert_routing("/web/locations/1", { :controller => 'web/locations', :action => 'show', :id => '1' })
    assert_routing({:method => 'put', :path => "/web/locations/1"}, 
                   {:controller => 'web/locations', :action => 'update', :id => '1' })
  end  
end