require 'test_helper'

class Web::WebControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end

  test 'guide' do
    get :guide
    assert_response :success
    assert_template "web/web/guide"
  end
  
  test 'topsites' do
    get :topsites
    assert_response :success
    assert_template "web/web/topsites"
  end  
  
  test 'home as anonymous' do
    get :home
    assert_response :success
    assert_template "web/web/home"
    form_attr = { :action => oauth_authorize_path, :method=>"get", :class=>"button_to" }
    assert_tag :tag => "form", :attributes => form_attr, 
                               :descendant => { :tag => "input", :attributes => { :type=>"submit" }}
  end
  
  test 'home as user' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    get :home
    assert_response :success
    assert_template "web/web/home"
    form_attr = { :action => new_web_investigator_path, :method=>"get", :class=>"button_to" }
    assert_tag :tag => "form", :attributes => form_attr, 
                               :descendant => { :tag => "input", :attributes => { :type=>"submit" }}
  end  
  
  test 'home as investigator' do
    @controller.login!(@user)
    get :home
    assert_response :success
    assert_template "web/web/home"
    form_attr = { :action => new_web_investigator_path, :method=>"get", :class=>"button_to" }
    assert_no_tag :tag => "form", :attributes => form_attr
  end  
  
  test 'routes' do
    assert_routing("/web", { :controller => 'web/web', :action => 'home' })
    assert_routing("/web/guide", { :controller => 'web/web', :action => 'guide' })
    assert_routing("/web/quickstart", { :controller => 'web/web', :action => 'quickstart' })
    assert_routing("/web/rules", { :controller => 'web/web', :action => 'rules' })
    assert_routing("/web/topsites", { :controller => 'web/web', :action => 'topsites' })
  end  
end
