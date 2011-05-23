require 'test_helper'

class Web::AlliesControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @ally = allies(:aleph_beth)
  end
  
  test 'index' do
    @controller.login!( users(:beth) )
    get :index
    assert_response :success
    assert_template "web/allies/index"
    assert !assigns(:allies).blank?
    assert !assigns(:friends).blank?
    assert !assigns(:contacts).blank?

    assigns(:friends).each do |friend|
      assert !friend.investigator_id.blank?
    end
  end
  
  test 'index with contacts' do
    @controller.login!( users(:aleph) )
    get :index
    assert_response :success
    assert_template "web/allies/index"
    assert !assigns(:contacts).blank?
    @user.investigator.contacts.each do |c|
      assert_tag :tag => "a", :attributes => { :href => web_contact_path(c) }
      assert_tag :tag => "a", :attributes => { :href => "http://www.facebook.com/addfriend.php?id=#{c.character.user.facebook_id}", }
    end
  end
  
  test 'index with empty friends' do
    user = users(:gimel)
    
    @controller.login!( user )
    get :index
    assert_response :success
    assert_template "web/allies/index"
    assert assigns(:allies).blank?
  end

  test 'index with introductions' do
    @user = users(:aleph)
    @investigator = investigators(:gimel_pi)
    @introducer = investigators(:aleph_pi)
    @character = characters(:thomas_malone)
    
    intro = Introduction.new(:introducer_id => @introducer.id, :investigator_id => @investigator.id, :character_id => @character.id)
    intro.save(:validates => false)
    @controller.login!( users(:gimel) )
    get :index
    assert_response :success
    assert_template "web/allies/index"
    assert assigns(:introductions).blank?
    
    assigns(:introductions).each do |intro|
      assert_tag :tag => "a", :attributes => { :href => web_introduction_path(intro), 'data-method' => "put"}
      assert_tag :tag => "a", :attributes => { :href => web_introduction_path(intro), 'data-method' => "delete"}
    end
  end

  test 'create' do
    @controller.login!( users(:beth) )
    users(:beth).investigator.allies.destroy_all
    assert_difference 'Ally.count', +1 do
      post :create, :ally => {:ally_id => investigators(:aleph_pi).id}
      assert_response :found
      assert !assigns(:ally).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_allies_path
      assert_equal assigns(:ally).investigator_id, users(:beth).investigator_id
      assert_equal assigns(:ally).ally_id, users(:aleph).investigator_id
    end
  end
  
  test 'destroy' do
    @controller.login!( @ally.investigator.user )
    assert_difference 'Ally.count', -1 do
      delete :destroy, :id => @ally.id
      assert_response :found
      assert_equal flash[:notice], "Ally removed from your Inner Circle."
      assert_redirected_to web_allies_path
    end
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
    @controller.login!( @user )
    
    get :index
    assert_investigator_required
    
    post :create
    assert_investigator_required 
    
    delete :destroy, :id => 1
    assert_investigator_required  
  end
    
  test 'routes' do
    assert_routing("/web/allies", { :controller => 'web/allies', :action => 'index' })
    assert_routing({:method => 'post', :path => "/web/allies"}, 
                   {:controller => 'web/allies', :action => 'create' })
    assert_routing({:method => 'delete', :path => "/web/allies/1"}, 
                   {:controller => 'web/allies', :action => 'destroy', :id => "1" })
  end  
end
