require 'test_helper'

class Web::IntroductionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:gimel_pi)
    @introducer = investigators(:aleph_pi)
    @contact = contacts(:aleph_thomas_malone)
    @character = characters(:thomas_malone)
  end
  
  def mock_intro_validations
    mock = flexmock(Introduction).new_instances
    mock.should_receive(:validates_introducer_favors).once
    mock.should_receive(:validates_introducer_location).once
    mock.should_receive(:use_favors).once
  end
  
  test 'create' do
    @introducer.allies.create(:ally_id => @investigator.id)
    @controller.login!(@user)
    mock_intro_validations 
    
    assert_difference 'Introduction.count', +1 do
      post :create, :contact_id => @contact.id, :investigator_id => @investigator.id
      assert_response :found
      assert !assigns(:contact).blank?
      assert !assigns(:investigator).blank?
      assert !assigns(:introduction).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_contact_path(@contact)
    end    
  end
  
  test 'update' do
    @introducer.allies.create(:ally_id => @investigator.id)
    @investigator.contacts.destroy_all
    mock_intro_validations
    @investigator.update_attribute(:location_id, @character.location_id)
    intro = Introduction.create(:introducer_id => @introducer.id, :investigator_id => @investigator.id, :character_id => @character.id)
    
    @controller.login!(@investigator.user)
    assert_difference 'Introduction.arranged.count', -1 do
      assert_difference '@investigator.contacts.count', +1 do
        put :update, :id => intro.id
        assert_response :found
        assert !assigns(:introduction).blank?
        assert !flash[:notice].blank?
        assert_redirected_to web_allies_path
      end    
    end  
    assert_equal 'accepted', assigns(:introduction).status
  end
  
  test 'delete' do
    @introducer.allies.create(:ally_id => @investigator.id)
    mock_intro_validations
    intro = Introduction.create(:introducer_id => @introducer.id, :investigator_id => @investigator.id, :character_id => @character.id)
    
    @controller.login!(@investigator.user)
    assert_difference 'Introduction.arranged.count', -1 do
      assert_no_difference '@investigator.contacts.count' do
        delete :destroy, :id => intro.id
        assert_response :found
        assert !assigns(:introduction).blank?
        assert !flash[:notice].blank?
        assert_redirected_to web_allies_path
      end    
    end  
    assert_equal 'dismissed', assigns(:introduction).status
  end
  
  test 'create failure' do  
    @controller.login!(@user)
    
    assert_no_difference 'Introduction.count' do
      post :create, :contact_id => @contact.id, :investigator_id => @investigator.id
      assert_response :found
      assert !assigns(:contact).blank?
      assert !assigns(:introduction).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_contact_path(@contact)
    end
  end    
  
  test 'require_user' do
    post :create, :contact_id => '1'
    assert_user_required
    
    put :update, :id => '1'
    assert_user_required
    
    delete :destroy, :id => '1'
    assert_user_required    
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    post :create, :contact_id => '1'
    assert_investigator_required
    
    put :update, :id => '1'
    assert_investigator_required
    
    delete :destroy, :id => '1'
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/web/introductions/1"}, 
                   {:controller => 'web/introductions', :action => 'update', :id => '1' })    
    assert_routing({:method => 'delete', :path => "/web/introductions/1"}, 
                   {:controller => 'web/introductions', :action => 'destroy', :id => '1' })                   
    assert_routing({:method => 'post', :path => "/web/contacts/1/introductions"}, 
                   {:controller => 'web/introductions', :action => 'create', :contact_id => '1' })
  end  
end