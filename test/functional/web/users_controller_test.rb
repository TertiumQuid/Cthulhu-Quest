require 'test_helper'

class Web::UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'show' do
    @controller.login!(@user)
    get :show
    assert_response :success
    assert_template "web/users/show"
    assert !assigns(:user).blank?
    assert_equal @user, assigns(:user)
  end

  test 'logout' do
    @controller.login!(@user)
    assert_not_nil @controller.current_user, "user required in session"
    delete :logout 
    assert_response :found
    assert_redirected_to root_path
    expected_session = {"user_id"=>nil, "flash"=>{:notice=>"You logged out."}}
    assert_equal expected_session, @controller.session, "session should be empty"
    assert_equal flash[:notice], "You logged out."
  end
  
  test 'require_user' do
    get :show
    assert_user_required
    
    delete :logout 
    assert_user_required
  end
  
  test 'routes' do
    assert_routing("/web/user", { :controller => 'web/users', :action => 'show' })
    assert_routing({:method => 'delete', :path => "/web/user/logout"}, 
                   {:controller => 'web/users', :action => 'logout' })    
  end  
end
