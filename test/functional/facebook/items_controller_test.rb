require 'test_helper'

class Facebook::ItemsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    init_signed_request
  end
  
  test 'index as anonymous' do
    get :index
    assert_response :success
    assert_template "facebook/items/index"
    
    assert !assigns(:items).blank?
    assert !assigns(:weapons).blank?
    assert !assigns(:artifacts).blank?
  end
  
  test 'index' do
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/items/index"
    
    assert !assigns(:items).blank?
    assert !assigns(:weapons).blank?
    assert !assigns(:artifacts).blank?
    
    assert !assigns(:weapon_ids).blank?
    assert !assigns(:item_ids).blank?
  end
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/items/index"
  end  
  
  test 'routes' do
    assert_routing("/facebook/items", { :controller => 'facebook/items', :action => 'index' })
  end  
end