require 'test_helper'

class Facebook::LocationsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @location = locations(:arkham)
    @transit = transits(:arkham_new_york)
    flexmock(@controller).should_receive(:award_daily_income)
    init_signed_request
  end
  
  def set_location
    @location = locations(:new_york)
    characters(:thomas_malone).update_attribute(:location_id, @location.id)
    @user.investigator.update_attribute(:location_id, @location.id)    
  end
    
  test 'default_location' do
    assert_equal @location, @controller.send(:default_location)
  end
  
  test 'show as anonymous' do
    characters(:thomas_malone).update_attribute(:location_id, @location.id)
    get :show
    assert_response :success
    assert_template "facebook/locations/show"
    assert !assigns(:location).blank?
    assert !assigns(:transits).blank?
    assert !assigns(:characters).blank?
    assert_equal @location, assigns(:location)
  end
  
  test 'show' do
    set_location
    
    get :show, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/locations/show"
    assert !assigns(:location).blank?
    assert !assigns(:transits).blank?
    assert !assigns(:characters).blank?
    assert_equal @location, assigns(:location)
  end  
  
  test 'show with introductions' do
    set_location
    Contact.destroy_all
    intro = @investigator.introductions.new(:character_id => characters(:thomas_malone).id, :status => 'arranged', :plot => Plot.first)
    intro.save(:validates => false)
    
    get :show, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/locations/show"
    assert !assigns(:introductions).blank?
  end
  
  test 'show with taskings' do
    flexmock(Tasking).new_instances.should_receive(:viable_for?).and_return(true)
    @user.investigator.update_attribute(:location_id, locations(:arkham).id)
    @user.investigator.update_attribute(:level, 100)
    
    get :show, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/locations/show"
    assert !assigns(:taskings).blank?    
  end  
  
  test 'show for js' do
    get :show, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/locations/show"
  end  
  
  test 'update' do
    @location = locations(:new_york)
    assert_difference '@investigator.reload.funds', -@transit.price do
      put :update, :id => @location.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to facebook_location_path
      assert_equal @location, @investigator.reload.location
    end
  end
  
  test 'update failure' do
    location = locations(:new_york)
    original_location = @investigator.location
    @investigator.update_attribute(:funds, 0)
    
    put :update, :id => location.id, :signed_request => @signed_request
    assert_response :found
    assert !flash[:error].blank?
    assert_redirected_to facebook_location_path
    assert_equal original_location, @investigator.reload.location
  end    
  
  test 'update for js' do
    @location = locations(:new_york)
    assert_difference '@investigator.reload.funds', -@transit.price do
      put :update, :id => @location.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert_js_response
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert_equal 'Traveling', json['title']
      assert !json['message'].blank?
      assert_equal @location, @investigator.reload.location
    end
  end  
  
  test 'require_user' do
    put :update, :id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing("/facebook/location", { :controller => 'facebook/locations', :action => 'show' })
    assert_routing({:method => 'put', :path => "/facebook/location"}, 
                   {:controller => 'facebook/locations', :action => 'update' })
    
  end  
end