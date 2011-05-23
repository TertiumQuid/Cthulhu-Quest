require 'test_helper'

class Facebook::SocialsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @social = socials(:beth_estate_auction)
    @social_function = social_functions(:dinner_reception)
    init_signed_request
  end
  
  def set_social_for_user(social=nil,user=nil)
    user ||= @user
    social ||= @social
    social.update_attribute(:investigator_id, user.investigator_id)
  end
  
  test 'create' do
    assert_difference ['Social.count'], +1 do
      post :create, :social_function_id => @social_function.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:social_function).blank?
      assert !assigns(:social).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_social_functions_path
    end    
  end  
  
  test 'create for js' do
    assert_difference ['Social.count'], +1 do
      post :create, :social_function_id => @social_function.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      json = JSON.parse(@response.body)
      assert_js_response
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end    
  end  
  
  test 'create failure' do
    set_social_for_user
    
    assert_no_difference ['Social.count'] do
      post :create, :social_function_id => @social_function.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:social_function).blank?
      assert !assigns(:social).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_social_functions_path
    end    
  end
  
  test 'create failure for js' do
    set_social_for_user
    
    assert_no_difference ['Social.count'] do
      post :create, :social_function_id => @social_function.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
    end    
  end  
  
  test 'update' do
    set_social_for_user
    @social.update_attribute(:appointment_at, Time.now - 5.minutes)

    assert_difference '@user.investigator.socials.hosted.count', +1 do    
      assert_difference '@user.investigator.socials.scheduled.active.count', -1 do
        put :update, :social_function_id => @social_function.id, :id => @social.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:social_function).blank?
        assert !assigns(:social).blank?
        assert !flash[:notice].blank?
        assert_redirected_to facebook_social_functions_path
      end
    end
  end
  
  test 'update for js' do
    set_social_for_user
    @social.update_attribute(:appointment_at, Time.now - 5.minutes)
    @social.update_attribute(:hosted_at, nil)

    assert_difference '@user.investigator.socials.hosted.count', +1 do    
      assert_difference '@user.investigator.socials.scheduled.active.count', -1 do
        put :update, :social_function_id => @social_function.id, :id => @social.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
      end
    end
  end  
  
  test 'failure_message' do
    @social.errors[:base] << 'test1'
    @social.errors[:base] << 'test2'
    @controller.instance_variable_set( '@social', @social )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@social_function', @social_function )
    expected = "You are now preparing for the #{@social_function.name}. In #{SocialFunction::TIMEFRAME} hours, your social function will be scheduled and can be hosted. Until that time, your allies may attend as guests, sharing in the event's comradarie."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'reward_message' do
    @social.logs = @social.send(:default_logs)
    @social.logs[:host_reward] = 'test1'
    @social.logs[:guest_rewards] << 'test2'
    @controller.instance_variable_set( '@social', @social )
    
    expected = "You concluded this social function, with the following results:\n\ntest1\ntest2"
    assert_equal expected, @controller.send(:reward_message)
  end
  
  test 'return_path' do
    assert_equal facebook_social_functions_path, @controller.send(:return_path)
  end  
  
  test 'require_user' do
    post :create, :social_function_id => 1
    assert_user_required
  end  

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    post :create, :social_function_id => 1, :signed_request => @signed_request
    assert_investigator_required   
  end  
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/facebook/social_functions/1/socials"}, 
                  {:controller => 'facebook/socials', :action => 'create', :social_function_id => '1' })
  end  
end