require 'test_helper'

class Web::SocialFunctionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @social_function = social_functions(:dinner_reception)
  end
  
  test 'index as anonymous' do
    get :index
    assert_response :success
    assert_template "web/social_functions/index"
    assert !assigns(:social_functions).blank?
    assert assigns(:social).blank?
    assert assigns(:socials).blank?
  end
  
  test 'index as investigator' do
    @controller.login!(@user)
    get :index
    assert_response :success
    assert_template "web/social_functions/index"
    assert !assigns(:social_functions).blank?
    
    assigns(:social_functions).each do |s|
      assert_tag :tag => "a", :attributes => { :href => web_social_function_socials_path(s), 'data-method'=> "post" }
    end    
  end 
  
  test 'index as investigator with social' do
    investigator = investigators(:beth_pi)
    @controller.login!(investigator.user)
    
    get :index
    assert_response :success
    assert_template "web/social_functions/index"
    assert !assigns(:social_functions).blank?
    assert !assigns(:social).blank?
    assert !assigns(:social).guests.blank?
    
    assigns(:social_functions).each do |s|
      assert_no_tag :tag => "a", :attributes => { :href => web_social_function_socials_path(s) }
    end
  end   
  
  test 'index as investigator with socials' do
    @controller.login!(@user)
    get :index
    assert_response :success
    assert_template "web/social_functions/index"
    assert !assigns(:social_functions).blank?
    assert !assigns(:socials).blank?
    
    assigns(:socials).each do |s|
      assert_tag :tag => "form", :attributes => { :action => web_social_guests_path(s, :status => 'defected') }
      assert_tag :tag => "form", :attributes => { :action => web_social_guests_path(s, :status => 'cooperated') }
    end    
  end  
  
  test 'routes' do
    assert_routing("/web/social_functions", { :controller => 'web/social_functions', :action => 'index' })
  end  
end