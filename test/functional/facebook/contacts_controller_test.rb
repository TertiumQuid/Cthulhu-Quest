require 'test_helper'

class Facebook::ContactsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @contact = contacts(:aleph_henry_armitage)
    init_signed_request
  end
  
  test 'index' do
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/contacts/index"
    assert !assigns(:contacts).blank?
  end
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/contacts/index"
    assert !assigns(:contacts).blank?
  end  
  
  test 'show' do
    get :show, :signed_request => @signed_request, :id => @contact.id
    assert_response :success
    assert_template "facebook/contacts/show"
    assert !assigns(:contact).blank?
    assert !assigns(:plots).blank?
  end
  
  test 'show in same location' do
    @contact.update_attribute(:favor_count, 10)
    @user.investigator.update_attribute(:location_id, @contact.character.location_id)
    
    get :show, :signed_request => @signed_request, :id => @contact.id
    assert_response :success
    assert_template "facebook/contacts/show"
    assert !assigns(:contact).blank?
  end  
  
  test 'show for js' do
    get :show, :signed_request => @signed_request, :id => @contact.id, :format => 'js'
    assert_response :success
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['html'].blank?
    assert !json['title'].blank?
  end  
  
  test 'entreat' do
    @contact.investigator.update_attribute(:location_id, @contact.character.location_id)
    
    assert_difference '@contact.reload.favor_count', +1 do
      put :entreat, :id => @contact.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:contact).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_contact_path(@contact)
    end
  end  
  
  test 'entreat for js' do
    @contact.investigator.update_attribute(:location_id, @contact.character.location_id)
    
    assert_difference '@contact.reload.favor_count', +1 do
      put :entreat, :id => @contact.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert_js_response
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end  
  
  test 'entreat failure' do
    @contact.investigator.update_attribute(:location_id, locations(:naples).id)
    
    assert_no_difference '@contact.reload.favor_count' do
      put :entreat, :id => @contact.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:contact).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_contact_path(@contact)
    end
  end
    
  test 'return_path' do
    @controller.instance_variable_set( '@contact', @contact )
    assert_equal facebook_contact_path(@contact), @controller.send(:return_path)
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@contact', @contact )
    assert_equal "You met with #{@contact.name} and confided your worst fears, entreating their help in your luckless investigations. You gained +1 favor which may be used to assign your contact to help with a plot intrigue.", @controller.send(:success_message)
  end
  
  test 'failure_message for not entreatable?' do
    flexmock(@contact).should_receive(:entreatable?).and_return(false).once
    @controller.instance_variable_set( '@contact', @contact )
    assert_equal "You cannot entreat your contact for more favor so soon; you must wait a decorous period.", @controller.send(:failure_message)
  end  

  test 'failure_message for not located?' do
    flexmock(@contact).should_receive(:located?).and_return(false).once
    @controller.instance_variable_set( '@contact', @contact )
    assert_equal "You must travel to #{@contact.character.location.name} to entreat #{@contact.name}'s favor.", @controller.send(:failure_message)
  end  
  
  test 'show_html' do
    opts = {:layout => false, :template => "facebook/contacts/show.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:show_html)
  end
  
  test 'require_user' do
    get :index
    assert_user_required
    
    get :show, :id => 1
    assert_user_required
    
    put :entreat, :id => 1
    assert_user_required    
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :index, :signed_request => @signed_request
    assert_investigator_required
    
    get :show, :signed_request => @signed_request, :id => 1
    assert_investigator_required    
    
    put :entreat, :signed_request => @signed_request, :id => 1
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing("/facebook/contacts", { :controller => 'facebook/contacts', :action => 'index' })
    assert_routing("/facebook/contacts/1", { :controller => 'facebook/contacts', :action => 'show', :id => '1' })
    assert_routing({:method => 'put', :path => "/facebook/contacts/1/entreat"}, 
                   {:controller => 'facebook/contacts', :action => 'entreat', :id => '1' })
    
  end  
end