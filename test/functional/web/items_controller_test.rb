require 'test_helper'

class Web::ItemsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'index as anonymous' do
    get :index
    assert_response :success
    assert_template "web/items/index"
    assert_no_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
  end
  
  test 'index as investigator' do
    @user.investigator.update_attribute(:funds, 1)
    @controller.login!(@user)
    get :index
    assert_response :success
    assert_template "web/items/index"
    assert_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
    assert_tag :tag => "form", :attributes => { :class => 'button_to', :method=>"post"}, 
                               :descendant => { :tag=>"input" , :attributes => {:type => "submit", :value => "Buy Now"}}    
    assert_tag :tag=>"input" , :attributes => {:type => "submit", :value => "Funds Lacking"}
  end  
  
  test 'artifacts as anonymous' do
    get :artifacts
    assert_response :success
    assert_template "web/items/artifacts"
    assert_no_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
  end
  
  test 'artifacts as investigator' do
    @user.investigator.update_attribute(:funds, 250)
    @controller.login!(@user)
    get :artifacts
    assert_response :success
    assert_template "web/items/artifacts"
    assert_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
    assert_tag :tag => "form", :attributes => { :class => 'button_to', :method=>"post"}, 
                               :descendant => { :tag=>"input" , :attributes => {:type => "submit", :value => "Buy Now"}}    
    assert_tag :tag=>"input" , :attributes => {:type => "submit", :value => "Funds Lacking"}
  end
    
  test 'routes' do
    assert_routing("/web/items", { :controller => 'web/items', :action => 'index' })
    assert_routing("/web/items/artifacts", { :controller => 'web/items', :action => 'artifacts' })
  end  
end