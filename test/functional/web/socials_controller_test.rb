require 'test_helper'

class Web::SocialsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @social = socials(:beth_estate_auction)
    @function = social_functions(:dinner_reception)
  end
  
  test 'create' do
    @controller.login!(@user)
    
    assert_difference ['Social.count'], +1 do
      post :create, :social_function_id => @function.id
      assert_response :found
      assert !assigns(:social_function).blank?
      assert !assigns(:social).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_social_functions_path
    end    
  end
  
  test 'create failure' do
    @controller.login!(@social.investigator.user)
    
    assert_no_difference ['Social.count'] do
      post :create, :social_function_id => @function.id
      assert_response :found
      assert !assigns(:social_function).blank?
      assert !assigns(:social).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_social_functions_path
    end    
  end  
  
  test 'require_user' do
    post :create, :social_function_id => 1
    assert_user_required
    
    put :update, :social_function_id => 1, :id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    post :create, :social_function_id => 1
    assert_investigator_required
    
    put :update, :social_function_id => 1, :id => 1
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/web/social_functions/1/socials"}, 
                   {:controller => 'web/socials', :action => 'create', :social_function_id => '1' })
    assert_routing({:method => 'put', :path => "/web/social_functions/1/socials/1"}, 
                   {:controller => 'web/socials', :action => 'update', :social_function_id => '1', :id => '1' })
  end  
end

