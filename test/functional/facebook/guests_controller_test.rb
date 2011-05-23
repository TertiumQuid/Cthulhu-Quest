require 'test_helper'

class Facebook::GuestsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @social = socials(:beth_estate_auction)
    @social.investigator.allies.create!(:ally => @user.investigator)
    @guest = guests(:aleph_beth_estate_auction)
    Guest.destroy_all
    init_signed_request
  end
  
  test 'new' do
    get :new, :social_id => @social.id, :signed_request => @signed_request
    assert_response :success
    assert !assigns(:social).blank?
    assert !assigns(:guest).blank?
    assert_response :success
    assert_template "facebook/guests/new"
  end  
  
  test 'new for js' do
    get :new, :social_id => @social.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert !assigns(:social).blank?
    assert !assigns(:guest).blank?
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['html'].blank?
  end
  
  test 'create' do
    assert_difference ['Guest.count','@social.guests.count'], +1 do
      post :create, :social_id => @social.id, :status => 'cooperated', :signed_request => @signed_request
      assert_response :found
      assert !assigns(:social).blank?
      assert !assigns(:guest).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_social_functions_path
    end
  end  
  
  test 'create failure' do  
    Ally.destroy_all
    assert_no_difference 'Guest.count' do
      post :create, :social_id => @social.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:error].blank?
      assert_redirected_to facebook_social_functions_path
    end    
  end 
  
  test 'create for js' do
    assert_difference ['Guest.count','@social.guests.count'], +1 do
      post :create, :social_id => @social.id, :status => 'cooperated', :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:social).blank?
      assert !assigns(:guest).blank?
      json = JSON.parse(@response.body)
      assert_js_response
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end   
  
  test 'return_path' do
    assert_equal facebook_social_functions_path, @controller.send(:return_path)
  end  
  
  test 'failure_message' do
    @guest.errors[:base] << 'test1'
    @guest.errors[:base] << 'test2'
    @controller.instance_variable_set( '@guest', @guest )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@social', @social )
    @controller.instance_variable_set( '@guest', @guest )
    expected = "You've pledged your attendance at the #{@social.social_function.name} where you will #{@guest.description}"
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'require_user' do
    get :new, :social_id => 1
    assert_user_required
    
    post :create, :social_id => 1
    assert_user_required    
  end  

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :new, :social_id => 1, :signed_request => @signed_request
    assert_investigator_required 
    
    post :create, :social_id => 1, :signed_request => @signed_request
    assert_investigator_required      
  end  
  
  test 'routes' do
    assert_routing("/facebook/socials/1/guests/new", { :controller => 'facebook/guests', :action => 'new', :social_id => '1' })        
    assert_routing({:method => 'post', :path => "/facebook/socials/1/guests"}, 
                  {:controller => 'facebook/guests', :action => 'create', :social_id => '1' })
  end  
end