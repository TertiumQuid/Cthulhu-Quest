require 'test_helper'

class Facebook::SocialFunctionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    init_signed_request
  end
  
  test 'index' do
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/social_functions/index"
    assert !assigns(:social_functions).blank?
    assert assigns(:social).blank?
  end  
  
  test 'index for anonymous' do
    get :index
    assert_response :success
    assert_template "facebook/social_functions/index"
    assert !assigns(:social_functions).blank?
  end  
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/social_functions/index"
  end  
  
  test 'index with social' do
    socials(:beth_estate_auction).update_attribute(:investigator_id, @user.investigator_id)
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert !assigns(:social_functions).blank?
    assert !assigns(:social).blank?
  end  
  
  test 'routes' do
    assert_routing("/facebook/social_functions", { :controller => 'facebook/social_functions', :action => 'index' })
  end  
end