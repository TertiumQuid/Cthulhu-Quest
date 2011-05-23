require 'test_helper'

class Facebook::FacebookControllerTest < ActionController::TestCase
  def setup
    init_signed_request
  end
  
  test 'home as anonymous' do
    get :home
    assert_response :success
    assert_template "facebook/facebook/home"
  end
  
  test 'home as user' do
    get :home, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/facebook/home"
    assert_equal @user, @controller.current_user
  end
  
  test 'home for js' do
    get :home, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/facebook/home"
  end  
  
  test 'authorized_facebook?' do
    assert_equal false, @controller.authorized_facebook?
    @controller.params[:facebook] = {}
    assert_equal false, @controller.authorized_facebook?
    @controller.params[:facebook] = {:test => '1'}
    assert_equal true, @controller.authorized_facebook?
  end
  
  test 'authorized_app?' do
    assert_equal false, @controller.authorized_app?
    @controller.params[:facebook] = {:user_id => '1'}
    assert_equal false, @controller.authorized_app?
    @controller.params[:facebook] = {:oauth_token => '123'}    
    assert_equal true, @controller.authorized_app?
  end
  
  test 'facebook_signed? true' do
    sig = '1234567890'
    flexmock(@controller).should_receive(:facebook_sig).and_return(sig).once
    assert_equal true, @controller.send(:facebook_signed?, sig, sig.reverse)
  end
  
  test 'facebook_signed? false' do
    sig = '1234567890'
    flexmock(@controller).should_receive(:facebook_sig).and_return('nomatch').once
    assert_equal false, @controller.send(:facebook_signed?, sig, sig.reverse)
  end  
  
  test 'routes' do
    assert_routing("/facebook", { :controller => 'facebook/facebook', :action => 'home' })
  end  
end
