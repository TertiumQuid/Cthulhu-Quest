require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
  end
  
  test 'display for web' do
    assert_equal 'web', @controller.display
  end
  
  test 'display for touch' do  
    @controller.request.env['HTTP_USER_AGENT'] = 'iPhone'
    assert_equal 'touch', @controller.display
    
    @controller.request.env['HTTP_USER_AGENT'] = 'Android'
    assert_equal 'touch', @controller.display    
  end
    
  test 'display for facebook' do      
    @controller.request.env['HTTP_USER_AGENT'] = 'Mozilla'
    @controller.params[:signed_request] = 'test'    
    assert_equal 'facebook', @controller.display    
    
    env = {}
    @controller.params[:signed_request] = nil
    flexmock(@controller).should_receive('request.env').and_return(env)    
    flexmock(@controller).should_receive('request.url').and_return('facebook/')
    assert_equal 'facebook', @controller.display
  end
  
  test 'facebook_client' do
    client = @controller.send(:facebook_client)
    assert client.is_a?(OAuth2::Client)
    assert_equal AppConfig.facebook.app_id, client.id
    assert_equal AppConfig.facebook.app_secret, client.secret
    assert_equal AppConfig.facebook.site, client.site
  end
  
  test 'current_investigator without user' do
    flexmock(@controller).should_receive(:current_user).and_return(nil)
    assert_nil @controller.send(:current_investigator), 'no investigator expected with nil current_user instance'
  end
  
  test 'current_investigator with user' do
    @user.investigator.destroy
    @controller.instance_variable_set( '@current_user', @user.reload )
    assert_nil @controller.send(:current_investigator), 'no investigator expected from current_user instance'
  end
  
  test 'current_investigator with investigator' do  
    assert @user.investigator, 'user investigator required'
    @controller.instance_variable_set( '@current_user', @user )
    assert_equal @user.investigator, @controller.send(:current_investigator), 'investigator expected from current_user instance'
  end  
  
  test 'landing from web' do
    get :landing
    assert_response :found
    assert_redirected_to web_root_path
  end
  
  test 'landing from touch iphone' do
    @controller.request.env['HTTP_USER_AGENT'] = 'iPhone'
    get :landing
    assert_response :found
    assert_redirected_to touch_root_path
  end  

  test 'landing from touch android' do
    @controller.request.env['HTTP_USER_AGENT'] = 'Android'
    get :landing
    assert_response :found
    assert_redirected_to touch_root_path
  end  
  
  test 'redirect_to_root' do
    path = @controller.root_display_path
    flexmock(@controller).should_receive(:redirect_to).once.with( path )
    @controller.send(:redirect_to_root)
  end
  
  test 'root_display_path' do
    flexmock(@controller).should_receive(:display).once.and_return('web')
    assert_equal web_root_path, @controller.root_display_path
    flexmock(@controller).should_receive(:display).once.and_return('touch')
    assert_equal touch_root_path, @controller.root_display_path
    flexmock(@controller).should_receive(:display).once.and_return('facebook')
    assert_equal facebook_root_path, @controller.root_display_path    
  end
  
  test 'require_investigator' do
    @controller.instance_variable_set('@current_user', @user)
    assert_equal true, @controller.send(:require_investigator), "require_investigator should return true for current_investigator"
  end
  
  test 'require_investigator redirect' do
    @user.investigator.destroy
    flexmock(@controller).should_receive(:redirect_to)
    @controller.instance_variable_set('@current_user', @user.reload)
    assert_nil @controller.current_user.investigator, "nil investigator required"
    assert_nil @controller.send(:require_investigator), "require_investigator should return false for nil current_investigator"
    assert !@controller.flash[:error].blank?, "error message should store in flash"
  end  
  
  test 'needs_daily_update? without investigator' do
    assert_equal false, @controller.send(:needs_daily_update?)
  end
  
  test 'needs_daily_update? without last_income_at' do  
    @investigator.update_attribute(:last_income_at,nil)
    @controller.instance_variable_set('@current_investigator', @investigator)
    assert_equal true, @controller.send(:needs_daily_update?)
  end
  
  test 'needs_daily_update? for recent' do  
    @investigator.update_attribute(:last_income_at,Time.now - 23.hours)
    @controller.instance_variable_set('@current_investigator', @investigator)
    assert_equal false, @controller.send(:needs_daily_update?)
  end  
  
  test 'needs_daily_update?' do  
    @investigator.update_attribute(:last_income_at,Time.now - 25.hours)
    @controller.instance_variable_set('@current_investigator', @investigator)
    assert_equal true, @controller.send(:needs_daily_update?)
  end  
  
  test 'award_daily_income not awarded' do
    @controller.instance_variable_set('@current_investigator', @investigator)
    
    flexmock(@controller).should_receive(:needs_daily_update?).and_return(false)
    assert_no_difference '@investigator.reload.funds' do
      @controller.send(:award_daily_income)
    end
    assert @controller.flash[:notice].blank?
  end
  
  test 'award_daily_income awarded' do  
    @controller.instance_variable_set('@current_investigator', @investigator)
    
    flexmock(@controller).should_receive(:needs_daily_update?).and_return(true)
    assert_difference '@investigator.reload.funds', @investigator.income do
      @controller.send(:award_daily_income)
    end
    assert !@controller.flash[:notice].blank?
  end
  
  test 'recover_daily_wounds not recovered' do  
    flexmock(@investigator).should_receive(:recover_wounds!).times(0)
    @controller.instance_variable_set('@current_investigator', @investigator)
    flexmock(@controller).should_receive(:needs_daily_update?).and_return(false)
    
    @controller.send(:award_daily_income)
  end
  
  test 'recover_daily_wounds recovered' do  
    flexmock(Investigator).new_instances.should_receive(:recover_wounds!).once    
    @controller.instance_variable_set('@current_investigator', @investigator)
    flexmock(@controller).should_receive(:needs_daily_update?).and_return(true)
    
    @controller.send(:award_daily_income)
  end  
  
  test 'rescue_from ActionController::InvalidAuthenticityToken' do
    flexmock(@controller).should_receive(:redirect_to_root).and_raise(ActionController::InvalidAuthenticityToken)
    flexmock(@controller).should_receive(:rescue_bad_token).once
    get :landing
  end
  
  test 'rescue_bad_token' do
    opts = { :title => "Session Timeout", :to => @controller.root_display_path }
    flexmock(@controller).should_receive(:render_and_respond).with( :session, opts )
    @controller.send(:rescue_bad_token)
  end  
  
  test 'update_from_facebook' do
    [nil,(Time.now - 9.hours)].each do |ts|
      @user.update_attribute(:last_facebook_update_at, ts)
      flexmock(@user).should_receive(:update_facebook_friends_from_access).once.and_return(true)
      @controller.instance_variable_set('@current_user', @user)
    
      assert_equal true, @controller.send(:update_from_facebook)
    end
  end
  
  test 'update_from_facebook ignored' do
    assert_nil @controller.send(:update_from_facebook)
  
    @user.update_attribute(:last_facebook_update_at, Time.now - 7.hours)
    @controller.instance_variable_set('@current_user', @user)
    
    assert_nil @controller.send(:update_from_facebook)
  end
  
  test 'routes' do
    assert_routing("/", { :controller => 'application', :action => 'landing' })
  end  
end