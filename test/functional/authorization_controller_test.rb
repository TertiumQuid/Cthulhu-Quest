require 'test_helper'

class AuthorizationControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'redirect_uri' do
    url = "http://#{AppConfig.domain}/oauth/callback?platform=web"
    assert_equal url, @controller.send(:redirect_uri)
  end
  
  test 'facebook redirect_uri' do
    flexmock(@controller).should_receive(:platform).and_return('facebook')
    url = "http://#{AppConfig.domain}/oauth/callback?platform=facebook"
    assert_equal url, @controller.send(:redirect_uri)
  end  
  
  test 'callback_redirect_url_for without investigator' do
    flexmock(@controller).should_receive(:display).and_return('web')
    assert_equal "/web/investigators/new", @controller.send(:callback_redirect_url_for, nil)
    @user.investigator_id = nil
    assert_equal "/web/investigators/new", @controller.send(:callback_redirect_url_for, @user)
  end

  test 'callback_redirect_url_for with investigator' do
    flexmock(@controller).should_receive(:display).and_return('web')
    assert_equal "/web/investigator/profile", @controller.send(:callback_redirect_url_for, @user)
  end

  test 'callback_redirect_url_for for custom' do
    flexmock(@controller).should_receive(:display).and_return('web')
    @controller.params[:platform] = 'custom'
    assert_equal "/custom/investigator/profile", @controller.send(:callback_redirect_url_for, @user)
  end

  test 'callback_redirect_url_for facebook' do
    flexmock(@controller).should_receive(:display).and_return('facebook')
    url = "http://apps.facebook.com/cthulhuquest/investigator/profile"
    assert_equal url, @controller.send(:callback_redirect_url_for, @user)
  end

  test 'callback blank' do
    get :callback
    assert_response :found
    assert_equal "User doesn't exist", flash[:notice]
    assert_redirected_to facebook_root_path
  end
  
  test 'callback for facebook denied' do
    get :callback, :error_description => "The user denied your request.", :error_reason => "user_denied", :error => "access_denied"
    assert_response :found
    assert_equal "Shan't you play? Ok, nevermind then. Maybe later?", flash[:notice]
    assert_redirected_to facebook_root_path
  end
      
  test 'platform' do
    assert_equal 'web', @controller.send(:platform)
    @controller.params[:controller] = 'web/investigators'
    assert_equal 'web', @controller.send(:platform)
    @controller.params[:controller] = 'facebook/investigators'
    assert_equal 'facebook', @controller.send(:platform)
    @controller.params[:controller] = 'touch/investigators'
    assert_equal 'touch', @controller.send(:platform)
    @controller.params[:platform] = 'custom'
    assert_equal 'custom', @controller.send(:platform)
  end
  
  test 'authorize' do
    client = @controller.send(:facebook_client)
    url = client.web_server.authorize_url(
      :redirect_uri => @controller.send(:redirect_uri),
      :scope => 'email,offline_access',
      :display => 'page'
    )
    get :authorize
    assert_response :found
    assert_redirected_to url
  end
  
  test 'callback with investigator' do
    assert_nil @controller.current_session.user_id, "nil user required"
    flexmock(User).should_receive(:find_or_create_from_access).and_return(@user)
    flexmock(@controller).should_receive('facebook_client.web_server.get_access_token').and_return(Object.new)
    get :callback, :code => '1234567890'
    assert_response :found
    assert !flash[:notice].blank?
    assert_equal @user.id, @controller.session[:user_id], "user should be logged into session"
    assert_equal @user.id, @controller.current_session.user_id, "user should be stored in current_user"
    assert_redirected_to edit_web_investigator_path
  end
  
  test 'callback without investigator' do
    assert_nil @controller.current_session.user_id, "nil user required"
    @user.update_attribute(:investigator_id, nil)
    
    flexmock(User).should_receive(:find_or_create_from_access).and_return(@user)
    flexmock(@controller).should_receive('facebook_client.web_server.get_access_token').and_return(Object.new)
    get :callback, :code => '1234567890'
    assert_response :found
    assert !flash[:notice].blank?
    assert_redirected_to new_web_investigator_path
  end  
  
  test 'callback failure' do
  end
  
  test 'deauthorize' do
    signed_request = "Ktiyol2jYd-G__8lEzNJ0WM10ACEat1hN6_ijNWAi6Q.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImlzc3VlZF9hdCI6MTMwMjY5ODkyOCwidXNlciI6eyJjb3VudHJ5IjoiY3oiLCJsb2NhbGUiOiJjc19DWiJ9LCJ1c2VyX2lkIjoiMCJ9"
    
    get :deauthorize, :signed_request => signed_request
    assert_response :success
    assert @response.body.blank?
  end
  
  test 'routes' do
    assert_routing("/oauth/authorize", { :controller => 'authorization', :action => 'authorize' })
    assert_routing("/oauth/callback", { :controller => 'authorization', :action => 'callback' })
  end  
end