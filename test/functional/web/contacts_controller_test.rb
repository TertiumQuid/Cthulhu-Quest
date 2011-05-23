require 'test_helper'

class Web::ContactsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @contact = contacts(:aleph_henry_armitage)
  end
  
  test 'show' do
    @controller.login!(@user)
    
    get :show, :id => @contact.id
    assert_response :success
    assert_template "web/contacts/show"
    assert !assigns(:contact).blank?
  end 
  
  test 'show with allies' do  
    @contact = contacts(:aleph_thomas_malone)
    @contact.update_attribute(:favor_count, 10)
    @user.investigator.update_attribute(:location_id, @contact.character.location_id)
    @user.investigator.allies.create(:ally_id => investigators(:gimel_pi).id)
    
    @controller.login!(@user)
    
    get :show, :id => @contact.id
    assert_response :success
    assert !assigns(:allies).blank?
    assigns(:allies).each do |ally|
      assert_tag :tag => "a", :attributes => {:href => web_contact_introductions_path(@contact.id, :investigator_id => ally.ally_id),
                                              'data-method' => 'post'}      
    end
  end
  
  test 'entreat' do
    @controller.login!(@user)
    @contact.investigator.update_attribute(:location_id, @contact.character.location_id)
    assert_difference '@contact.reload.favor_count', +1 do
      put :entreat, :id => @contact.id
      assert_response :found
      assert !assigns(:contact).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_contact_path(@contact)
    end
  end  

  test 'entreat located failure' do
    @controller.login!(@user)
    @contact.investigator.update_attribute(:location_id, locations(:naples).id)
    assert_no_difference '@contact.reload.favor_count' do
      put :entreat, :id => @contact.id
      assert_response :found
      assert !assigns(:contact).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_contact_path(@contact)
    end
  end  
  
  test 'entreat entreatable failure' do
    @controller.login!(@user)
    @contact.update_attribute(:last_entreated_at, Time.now)
    assert_no_difference '@contact.reload.favor_count' do
      put :entreat, :id => @contact.id
      assert_response :found
      assert !assigns(:contact).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_contact_path(@contact)
    end
  end  
  
  test 'require_user' do
    get :show, :id => '1'
    assert_user_required
    
    put :entreat, :id => '1'
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    get :show, :id => '1'
    assert_investigator_required  
    
    put :entreat, :id => '1'
    assert_investigator_required   
  end  
  
  test 'routes' do
    assert_routing("/web/contacts/1", { :controller => 'web/contacts', :action => 'show', :id => '1' })
    assert_routing({:method => 'put', :path => "/web/contacts/1/entreat"}, 
                   {:controller => 'web/contacts', :action => 'entreat', :id => '1' })
    
  end
end