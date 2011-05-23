require 'test_helper'

class Facebook::AlliesControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @ally = allies(:aleph_beth)
    init_signed_request
  end
  
  test 'index' do
    Guest.destroy_all
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/allies/index"
    assert !assigns(:allies).blank?
    assert !assigns(:friends).blank?
  end
  
  test 'index with socials' do
    Guest.destroy_all
    @ally.ally.allies.create!(:ally => @ally.investigator)
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/allies/index"
    assert !assigns(:socials).all.blank?
  end
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_template "facebook/allies/index"
    assert_html_response
  end
    
  test 'create' do
    @ally.destroy
    
    assert_difference ['Ally.count','@user.investigator.allies.count'], +1 do
      post :create, :ally => {:ally_id => @ally.ally_id}, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:ally).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_allies_path
      assert_equal assigns(:ally).investigator, @ally.investigator
      assert_equal assigns(:ally).ally_id, @ally.ally_id
    end
  end 
  
  test 'create for js' do
    @ally.destroy
    
    assert_difference ['Ally.count','@user.investigator.allies.count'], +1 do
      post :create, :ally => {:ally_id => @ally.ally_id}, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:ally).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['to'].blank?
    end
  end   
  
  test 'destroy' do
    assert_difference ['Ally.count','@user.investigator.allies.count'], -1 do
      delete :destroy, :signed_request => @signed_request, :id => @ally.id
      assert_response :found
      assert_equal flash[:notice], "Ally removed from your Inner Circle."
      assert_redirected_to facebook_allies_path
    end
  end
  
  test 'destroy for js' do
    assert_difference ['Ally.count','@user.investigator.allies.count'], -1 do
      delete :destroy, :signed_request => @signed_request, :id => @ally.id, :format => 'js'
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['to'].blank?
    end
  end
  
  test 'success_message' do
    @controller.instance_variable_set( '@ally', @ally )
    expected = "You inducted the worthy #{@ally.name} to your Inner Circle. You'll now be able to request their investigative skills with plot intrigues."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'failure_message' do
    @ally.errors[:base] << 'test1'
    @ally.errors[:base] << 'test2'
    @controller.instance_variable_set( '@ally', @ally )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'return_path' do
    assert_equal facebook_allies_path, @controller.send(:return_path)
  end  
  
  test 'require_user' do
    get :index
    assert_user_required
    
    post :create
    assert_user_required    
    
    delete :destroy, :id => 1
    assert_user_required
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :index, :signed_request => @signed_request
    assert_investigator_required
    
    post :create, :signed_request => @signed_request
    assert_investigator_required    
    
    delete :destroy, :signed_request => @signed_request, :id => 1
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing("/facebook/allies", { :controller => 'facebook/allies', :action => 'index' })
    assert_routing({:method => 'post', :path => "/facebook/allies"}, 
                   {:controller => 'facebook/allies', :action => 'create' })
    assert_routing({:method => 'delete', :path => "/facebook/allies/1"}, 
                   {:controller => 'facebook/allies', :action => 'destroy', :id => "1" })
  end  
end