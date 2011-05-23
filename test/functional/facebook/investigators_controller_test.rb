require 'test_helper'

class Facebook::InvestigatorsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
  end
  
  def prepare_for_create
    flexmock(@controller).should_receive(:require_authorized_login).once
    @user.investigator.destroy
    @user.update_attribute(:investigator_id, nil)
    @params = {:profile_id => Profile.first.id, :name => 'test'}
  end
  
  def assert_gift_form(investigator_id)
    assert_tag :tag => "form", :attributes => { 
      :action => facebook_investigator_gift_path( investigator_id ), :method=>"post"
    }    
    assert_tag :tag => "form", :descendant => {
      :tag => "input", :attributes => { :type=>"text", :name=>"gift[gifting]" } 
    }
    assert_tag :tag => "form", :descendant => { :tag=>"input", :attributes => { :type => "submit" }}    
  end
  
  test 'show' do
    init_signed_request
    investigator_id = investigators(:beth_pi).id
    get :show, :signed_request => @signed_request, :id => investigator_id
    assert_response :success
    assert_template "facebook/investigators/show"
    assert !assigns(:investigator).blank?
    assert !assigns(:ally).blank?
    assert !assigns(:assignments).blank?
    assert !assigns(:gift).blank?
    assert_gift_form( investigator_id )
  end  
  
  test 'show with psychoses' do
    init_signed_request
    ally = investigators(:beth_pi)
    ally.psychoses.create(:insanity => insanities(:nightmares))
    
    get :show, :signed_request => @signed_request, :id => ally.id
    assert_response :success
    assert !assigns(:psychoses).blank?
  end
  
  test 'show with medical' do
    init_signed_request
    ally = investigators(:beth_pi)
    ally.update_attribute(:wounds, 3)
    item = items(:first_aid_kit)
    possessions(:aleph_lantern).update_attribute(:item_id, item.id)
    
    get :show, :signed_request => @signed_request, :id => ally.id
    assert_response :success
    assert !assigns(:medical).blank?
    assert !assigns(:ally).blank?
  end  
  
  test 'show with spirits' do
    init_signed_request
    ally = investigators(:beth_pi)
    ally.update_attribute(:madness, 3)
    
    get :show, :signed_request => @signed_request, :id => ally.id
    assert_response :success
    assert !assigns(:spirits).blank?
    assert !assigns(:ally).blank?
  end  
  
  test 'show for js' do
    init_signed_request
    get :show, :signed_request => @signed_request, :id => investigators(:beth_pi).id, :format => 'js'
    assert_response :success
    assert !assigns(:investigator).blank?
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['html'].blank?
    assert !json['title'].blank?
  end  
  
  test 'show as anonymous' do
    get :show, :id => investigators(:beth_pi).id
    assert_response :success
    assert_template "facebook/investigators/show"
    assert !assigns(:investigator).blank?
  end
  
  test 'new as anonymous' do
    get :new
    assert_response :success
    assert_template "facebook/investigators/new"
  
    assert_tag :tag => "form", :attributes => { :action => facebook_investigators_path, :method=>"post"}
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"text",:name=>"investigator[name]"} }
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"hidden",:name=>"investigator[profile_id]"} }
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"submit"}}    
  end  
  
  test 'new with user' do  
    @user.investigator.destroy
    init_signed_request
    get :new, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/investigators/new"
    
    assert_no_tag :tag => "a", :attributes => {:href => oauth_authorize_path(:platform => 'facebook')}
    assert_tag :tag => "form", :attributes => { :action => facebook_investigators_path, :method=>"post"}
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"submit"}}        
  end
  
  test 'new for js' do
    get :new, :format => 'js'
    assert_response :success
    assert_template "facebook/investigators/new"
    assert_html_response
  end
  
  test 'create for html' do
    prepare_for_create
    init_signed_request
    params = {:profile_id => Profile.first.id, :name => 'test'}
    assert_difference 'Investigator.count', +1 do
      post :create, :signed_request => @signed_request, :investigator => params
      assert_response :found
      assert !assigns(:investigator).blank?
      assert_equal params[:name], assigns(:investigator).name
      assert_equal params[:profile_id], assigns(:investigator).profile_id
      assert_redirected_to edit_facebook_investigator_path
    end
  end
  
  test 'create for session' do
    prepare_for_create
    init_signed_request
    @controller.session[:investigator_params] = @params
    
    assert_difference 'Investigator.count', +1 do
      post :create, :signed_request => @signed_request
      assert !assigns(:investigator).blank?
      assert_equal @params[:name], assigns(:investigator).name
      assert_equal @params[:profile_id], assigns(:investigator).profile_id
    end
  end  
  
  test 'create failure for html' do
    flexmock(@controller).should_receive(:require_authorized_login).once
    @user.investigator.destroy
    init_signed_request
    assert_no_difference 'Investigator.count' do
      post :create, :signed_request => @signed_request, :investigator => {}
      assert_response :found
      assert !assigns(:investigator).blank?
      assert_redirected_to new_facebook_investigator_path
    end
  end  
  
  test 'create for js' do
    prepare_for_create
    init_signed_request
    assert_difference 'Investigator.count', +1 do
      post :create, :signed_request => @signed_request, :format => 'js', :investigator => @params
      assert_response :success
      assert !assigns(:investigator).blank?
      json = JSON.parse(@response.body)
      assert_equal 'redirect', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['to'].blank?
    end
    assert_js_response
  end  
  
  test 'create failure for js' do
    flexmock(@controller).should_receive(:require_authorized_login).once
    @user.investigator.destroy
    init_signed_request
    assert_no_difference 'Investigator.count' do
      post :create, :signed_request => @signed_request, :format => 'js', :investigator => {}
      assert_response :success
      assert !assigns(:investigator).blank?
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
    assert_js_response
  end  
  
  test 'create without authorized login' do
    init_signed_request
    @user.destroy
    params = {:profile_id => Profile.first.id, :name => 'test'}
    
    assert_no_difference 'Investigator.count' do
      post :create, :signed_request => @signed_request, :format => 'js', :investigator => params
      assert_response :success
      assert !session[:investigator_params].blank?
      json = JSON.parse(@response.body)
      assert_equal 'redirect', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['to'].blank?
    end
    assert_js_response
  end  
  
  test 'edit' do
    init_signed_request
    get :edit, :signed_request => @signed_request
    
    assert_response :success
    assert !assigns(:investigator).blank?   
    assert !assigns(:books).blank?
    assert !assigns(:equipment).blank?
    assert !assigns(:armaments).blank?
    assert !assigns(:stats).blank?
    assert_template "facebook/investigators/edit"
    assert_html_response
  end
  
  test 'edit for js' do
    init_signed_request
    get :edit, :signed_request => @signed_request, :format => 'js'
    
    assert_response :success
    assert !assigns(:investigator).blank?   
    assert !assigns(:books).blank?
    assert !assigns(:equipment).blank?
    assert !assigns(:armaments).blank?
    assert !assigns(:stats).blank?
    assert_template "facebook/investigators/edit"
    assert_html_response
  end  
  
  test 'edit with medical items' do
    init_signed_request
    item = items(:first_aid_kit)
    possessions(:aleph_lantern).update_attribute(:item_id, item.id)
    get :edit, :signed_request => @signed_request
    
    assert_response :success
    assert !assigns(:equipment).blank?
    assert !assigns(:medical).blank?
  end
  
  test 'edit with psychoses' do
    @user.investigator.psychoses.create!(:insanity => insanities(:nightmares))
  
    init_signed_request
    get :edit, :signed_request => @signed_request
    assert_response :success
    assert !assigns(:psychoses).blank?
  end
  
  test 'destroy' do
    init_signed_request
    
    assert_not_nil @user.investigator
    delete :destroy, :signed_request => @signed_request
    assert_nil @user.reload.investigator
    
    assert_response :found
    assert !flash[:notice].blank?
    assert_redirected_to new_facebook_investigator_path
  end
  
  test 'destroy for js' do
    init_signed_request
    
    assert_not_nil @user.investigator
    delete :destroy, :signed_request => @signed_request, :format => 'js'
    assert_nil @user.reload.investigator
    
    assert_response :success
    assert !flash[:notice].blank?
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'redirect', json['status']
    assert !json['title'].blank?
    assert !json['to'].blank?
    assert !json['message'].blank?
  end  
  
  test 'show_html' do
    opts = {:layout => false, :template => "facebook/investigators/show.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:show_html)
  end
  
  test 'failure_message' do
    @user.investigator.errors[:base] << 'test1'
    @user.investigator.errors[:base] << 'test2'
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'success_message' do
  @controller.instance_variable_set( '@investigator', @user.investigator )  
  expected = "#{@user.investigator.name} has entered the world, crossing the threshold of ignorance into a terrifying knowledge of the forces which oppose mankind."
  assert_equal expected, @controller.send(:success_message)
  end
  
  test 'retired_message' do
    expected = "Few can escape the madness and damnation awaiting those who would seek the invisible forces governing our universe, but if you retire now you just might be able to return to a happy sheltered life and spend your remaining years forgetting the true horror of what you've learned."
    assert_equal expected, @controller.send(:retired_message)
  end
  
  test 'return_path with new investigator' do
    @controller.instance_variable_set( '@investigator', Investigator.new )
    assert_equal new_facebook_investigator_path, @controller.send(:return_path)
  end  
  
  test 'return_path with investigator' do
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_equal edit_facebook_investigator_path, @controller.send(:return_path)
  end  
  
  test 'investigator_params' do
    assert_nil @controller.send(:investigator_params)
    
    params = {:investigator => {:name => 'session'}}
    @controller.session[:investigator_params] = params
    assert_equal params, @controller.send(:investigator_params)
        
    params = {:investigator => {:name => 'params'}}
    @controller.params[:investigator] = params
    assert_equal params, @controller.send(:investigator_params)
  end
  
  test 'require_authorized_login with user' do
    @controller.instance_variable_set( '@current_user', @user )
    assert_equal true, @controller.send(:require_authorized_login)
  end
  
  test 'require_authorized_login without user' do
    params = {:investigator => {:name => 'test'}}
    response = {:message => "Please login with your Facebook account to continue.", :title => 'Facebook Connect', :to => oauth_authorize_path(:platform => 'facebook')}
    
    @controller.params[:investigator] = params
    flexmock(@controller).should_receive(:render_and_respond).with(:redirect, response).once
    
    assert_equal false, @controller.send(:require_authorized_login)
    assert_equal params, session[:investigator_params]
  end
  
  test 'require_user' do
    get :edit
    assert_user_required    
    
    delete :destroy
    assert_user_required    
  end
      
  test 'require_investigator' do
    init_signed_request
    assert @user.investigator.destroy
    
    get :edit, :signed_request => @signed_request
    assert_investigator_required
    
    delete :destroy, :signed_request => @signed_request
    assert_investigator_required
  end  
  
  test 'require_no_investigator' do
    init_signed_request
    
    get :new, :signed_request => @signed_request
    assert_response :found
    assert_redirected_to edit_facebook_investigator_path
    
    post :create, :signed_request => @signed_request
    assert_response :found
    assert_redirected_to edit_facebook_investigator_path
  end
  
  test 'routes' do
    assert_routing("/facebook/investigator/profile", { :controller => 'facebook/investigators', :action => 'edit' })
    assert_routing("/facebook/investigators/new", { :controller => 'facebook/investigators', :action => 'new' })
    assert_routing("/facebook/investigators/1", { :controller => 'facebook/investigators', :action => 'show', :id => '1' })
    assert_routing({:method => 'post', :path => "/facebook/investigators"}, 
                   {:controller => 'facebook/investigators', :action => 'create' })
    assert_routing({:method => 'delete', :path => "/facebook/investigator"}, 
                   {:controller => 'facebook/investigators', :action => 'destroy' })
                   
  end  
end