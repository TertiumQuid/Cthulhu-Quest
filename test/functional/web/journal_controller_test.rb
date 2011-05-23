require 'test_helper'

class Web::JournalControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'show' do
    @controller.login!(@user)
    get :show
    assert_response :success
    assert_template "web/journal/show"
    assert !assigns(:journal).blank?
  end  
  
  test 'routes' do
    assert_routing("/web/journal", { :controller => 'web/journal', :action => 'show' })
  end  
end