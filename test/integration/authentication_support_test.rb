require 'test_helper'

class AuthenticationSupportTest < ActionController::IntegrationTest
  def setup
    @user = users(:aleph)
    get '/'
  end
  
  def assert_login_cookie
    assert_not_nil @controller.send(:cookies)[:_cthulhu_quest_nonce]
  end
  
  test 'session_id' do
    current_session = @controller.current_session
    assert_not_nil current_session, 'session should never be null'
    
    expected_session = @controller.current_session
    assert_equal expected_session.id, current_session.id, 'session should be cached but different session returned'
  end  
  
  test 'current_session' do
    assert session = Session.create
    flexmock(@controller).should_receive(:session_id).and_return( session.session_id )
    assert_equal session, @controller.current_session
  end  
  
  test 'current_user from session' do
    @user.update_attribute(:last_login_at, nil)
    @controller.session[:user_id] = @user.id
    flexmock(@controller).should_receive(:recover_daily_wounds).ordered.once
    flexmock(@controller).should_receive(:award_daily_income).ordered.once
    flexmock(@controller).should_receive(:update_from_facebook).ordered.once
    
    assert_equal @user, @controller.current_user
    assert_not_nil @user.reload.last_login_at
  end  
  
  test 'current_user from cookie' do
    cookies = @controller.send(:cookies)
    cookies[:_cthulhu_quest_nonce] = 'cookie'
    @user.update_attribute(:nonce, 'cookie')
    @user.update_attribute(:last_login_at, nil)
    
    assert_equal @user, @controller.current_user
    assert_equal @user.id, @controller.session[:user_id]
    assert_not_equal @user.reload.nonce, 'cookie'
    assert_not_nil @user.reload.last_login_at
  end  
  
  test 'current_user from facebook params' do
    @controller.params[:facebook] = {:user_id => @user.facebook_id}
    assert_equal @user, @controller.current_user
    assert_not_nil @user.reload.last_login_at
  end
  
  test 'current_user blank' do
    assert_nil @controller.current_user
  end
  
  test 'login by id' do
    @controller.session[:user_id] = nil
    @user.update_attribute(:nonce, nil)
    flexmock(@controller).should_receive(:award_daily_income).once
    flexmock(@controller).should_receive(:update_from_facebook).once
    @controller.login!(@user.id)
    assert_equal @user.id, @controller.session[:user_id]
    assert_equal @user.id, @controller.current_session.user_id
    @user.reload
    assert_not_nil @user.nonce
    assert_login_cookie
  end
  
  test 'login by user' do
    assert_nil @user.nonce
    flexmock(@controller).should_receive(:award_daily_income).once
    flexmock(@controller).should_receive(:update_from_facebook).once
    @controller.login!(@user)
    assert_equal @user.id, @controller.session[:user_id]
    assert_equal @user.id, @controller.current_session.user_id
    @user.reload
    assert_not_nil @user.nonce
    assert_login_cookie
  end
  
  test 'login blank' do
    flexmock(@controller).should_receive(:award_daily_income).times(0)
    flexmock(@controller).should_receive(:update_from_facebook).times(0)
    assert_nil @controller.login!(nil)
    assert_nil @controller.session[:user_id]
  end
  
  test 'require_user' do
    @controller.instance_variable_set('@current_user', @user)
    assert_equal true, @controller.require_user
  end
  
  test 'require_user redirect with html' do
    flexmock(@controller).should_receive(:redirect_to).once
    assert_nil @controller.current_user, "nil user required"
    assert_nil @controller.require_user, "require_user should return nil for nil current_user"
    assert !@controller.flash[:error].blank?, "error message should store in flash"
  end  
  
  test 'require_user redirect with js' do
    get '/', :format => 'js'
    flexmock(@controller).should_receive(:render_json_response).once
    assert_nil @controller.current_user, "nil user required"
    assert_nil @controller.require_user, "require_user should return nil for nil current_user"
  end  
  
  test 'store_login_cookie' do  
    @user.update_attribute(:nonce, 'cookie')
    @controller.session[:user_id] = @user.id
    @controller.store_login_cookie         
    assert_equal 'cookie', @controller.send(:cookies)[:_cthulhu_quest_nonce]
  end
    
  test 'store_login_cookie without user' do
    @controller.store_login_cookie
    assert_nil @controller.send(:cookies)[:_cthulhu_quest_nonce]
  end
  
  test 'store_login_cookie without nonce' do
    @controller.session[:user_id] = @user.id
    @controller.store_login_cookie
    assert_nil @controller.send(:cookies)[:_cthulhu_quest_nonce]
  end  
  
  test 'delete_login_cookie' do
    @controller.send(:cookies)[:_cthulhu_quest_nonce] = 'cookie'
    assert_equal 'cookie', @controller.send(:cookies)[:_cthulhu_quest_nonce]
    @controller.delete_login_cookie
    assert_nil @controller.send(:cookies)[:_cthulhu_quest_nonce]
  end
end
