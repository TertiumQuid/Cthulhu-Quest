require 'test_helper'

class Web::WeaponsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  test 'index as anonymous' do
    get :index
    assert_response :success
    assert_template "web/weapons/index"
    assert_no_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
  end
  
  test 'index as investigator' do
    @user.investigator.update_attribute(:funds, 100)
    @controller.login!(@user)
    get :index
    assert_response :success
    assert_template "web/weapons/index"
    assert_tag :tag => "article", :attributes => { :class => 'sidebar funds'}
    assert_tag :tag => "form", :attributes => { :class => 'button_to', :method=>"post"}, 
                               :descendant => { :tag=>"input" , :attributes => {:type => "submit", :value => "Buy Now"}}    
    assert_tag :tag=>"input" , :attributes => {:type => "submit", :value => "Funds Lacking"}
  end  
  
  test 'routes' do
    assert_routing("/web/weapons", { :controller => 'web/weapons', :action => 'index' })
  end  
end