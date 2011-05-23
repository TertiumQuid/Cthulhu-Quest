require 'test_helper'

class Touch::TouchControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'home as anonymous' do
    get :home
    assert_response :success
    assert_template "touch/touch/home"
    assert_tag :tag => "a", :attributes => {:href => oauth_authorize_path(:display => 'touch'), :target => '_webapp'}
  end
  
  test 'home as user' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    get :home
    assert_response :success
    assert_template "touch/touch/home"
    assert_no_tag :tag => "a", :attributes => {:href => oauth_authorize_path(:display => 'touch'), :target => '_webapp'}
  end  
  
  test 'home as investigator' do
    @controller.login!(@user)
    get :home
    assert_response :success
    assert_template "touch/touch/home"
  end  
  
  test 'routes' do
    assert_routing("/touch", { :controller => 'touch/touch', :action => 'home' })
  end  
end
