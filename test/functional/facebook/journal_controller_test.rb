require 'test_helper'

class Facebook::JournalControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    init_signed_request
  end
  
  test 'show' do
    get :show, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/journal/show"
    assert !assigns(:journal).blank?
  end  
  
  test 'show for js' do
    get :show, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/journal/show"
  end  
  
  test 'require_user' do
    get :show
    assert_user_required
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :show, :signed_request => @signed_request
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing("/facebook/journal", { :controller => 'facebook/journal', :action => 'show' })
  end  
end