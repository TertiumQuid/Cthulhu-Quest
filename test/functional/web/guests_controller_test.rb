require 'test_helper'

class Web::GuestsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @social = socials(:beth_estate_auction)
  end
  
  test 'create' do
    Guest.destroy_all
    allies(:beth_gimel).update_attribute(:ally_id, @investigator.id)
    @controller.login!(@user)
    
    assert_difference 'Guest.count', +1 do
      post :create, :social_id => @social.id, :status => 'cooperated'
      assert_response :found
      assert !assigns(:social).blank?
      assert !assigns(:guest).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_social_functions_path
    end
  end
  
  test 'create failure' do  
    @controller.login!(@user)
    
    assert_no_difference 'Guest.count' do
      post :create, :social_id => @social.id
      assert_response :found
      assert !assigns(:social).blank?
      assert !assigns(:guest).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_social_functions_path
    end    
  end
  
  test 'require_user' do
    post :create, :social_id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    post :create, :social_id => 1
    assert_investigator_required   
  end
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/web/socials/1/guests"}, 
                   {:controller => 'web/guests', :action => 'create', :social_id => '1' })
  end  
end