require 'test_helper'

class Facebook::IntroductionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @contact = contacts(:aleph_thomas_malone)
    @introduced = investigators(:gimel_pi)
    @introduction = introductions(:gimel_robert_blake_aleph)
    init_signed_request
  end
  
  def create_introduction(investigator_id=nil,introducer_id=nil)
    @contact.update_attribute(:favor_count, 3)
    investigators(:aleph_pi).update_attribute(:location_id, characters(:thomas_malone).location_id)
    @introduction = Introduction.create!(:character_id => characters(:thomas_malone).id, :introducer_id => (introducer_id || @investigator.id), :investigator_id => (investigator_id || @introduced.id), :message => 'test')
  end
  
  def mock_introduction_validations
    investigators(:aleph_pi).allies.create(:ally_id => investigators(:gimel_pi).id)
    
    mock = flexmock(Introduction).new_instances
    mock.should_receive(:validates_introducer_favors).once
    mock.should_receive(:validates_introducer_location).once
    mock.should_receive(:use_favors).once
  end  
  
  test 'create' do
    mock_introduction_validations 
    
    assert_difference 'Introduction.count', +1 do
      post :create, :contact_id => @contact.id, :investigator_id => @introduced.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:contact).blank?
      assert !assigns(:investigator).blank?
      assert !assigns(:introduction).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_contacts_path
    end    
  end
  
  test 'create for js' do
    mock_introduction_validations 
    
    assert_difference 'Introduction.count', +1 do
      post :create, :contact_id => @contact.id, :investigator_id => @introduced.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:contact).blank?
      assert !assigns(:investigator).blank?
      assert !assigns(:introduction).blank?
      json = JSON.parse(@response.body)
      assert_js_response
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end    
  end
  
  test 'create failure' do
    assert_no_difference 'Introduction.count' do
      post :create, :contact_id => @contact.id, :investigator_id => @introduced.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:error].blank?
      assert_redirected_to facebook_contacts_path
    end    
  end  
    
  test 'update' do
    assert_difference '@investigator.introductions.arranged.count', -1 do
      assert_difference '@investigator.contacts.count', +1 do
        put :update, :id => @introduction.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:introduction).blank?
        assert !flash[:notice].blank?
        assert_redirected_to facebook_character_path(@introduction.character_id)
      end    
    end  
    assert_equal 'accepted', assigns(:introduction).status
  end  
  
  test 'update failure' do
    @introduction.investigator.update_attribute(:location_id, locations(:rome).id)
    assert_no_difference ['@introduction.investigator.introductions.arranged.count','@introduction.investigator.contacts.count'] do
      put :update, :id => @introduction.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:introduction).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_character_path(@introduction.character_id)
    end  
    assert_equal 'arranged', @introduction.reload.status
  end    

  test 'update for js' do
    assert_difference '@investigator.introductions.arranged.count', -1 do
      assert_difference '@investigator.contacts.count', +1 do
        put :update, :id => @introduction.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
      end    
    end  
    assert_equal 'accepted', assigns(:introduction).status
  end
  
  test 'delete' do
    assert_difference 'Introduction.arranged.count', -1 do
      assert_no_difference '@investigator.contacts.count' do
        delete :destroy, :id => @introduction.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:introduction).blank?
        assert !flash[:notice].blank?
        assert_redirected_to facebook_character_path(@introduction.character_id)
      end    
    end  
    assert_equal 'dismissed', assigns(:introduction).status    
  end
  
  test 'delete for js' do
    assert_difference 'Introduction.arranged.count', -1 do
      assert_no_difference '@investigator.contacts.count' do
        delete :destroy, :id => @introduction.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
      end    
    end  
    assert_equal 'dismissed', assigns(:introduction).status    
  end  
      
  test 'failure_message' do
    create_introduction
    @introduction.errors[:base] << 'test1'
    @introduction.errors[:base] << 'test2'
    @controller.instance_variable_set( '@introduction', @introduction )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'success_message with funds' do
    investigator = investigators(:gimel_pi)
    @controller.instance_variable_set( '@investigator', investigator )
    @controller.instance_variable_set( '@contact', @contact )
    
    expected = "Earnestly vouching the quality and character of your trusted friend, #{investigator.name}, you arrange for #{@contact.name} to meet them on your good word. If they accept the introduction you'll receive a measure of experience, yet should they rudely dismiss your gesture your contact will hold you accountable."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'acceptance_message' do
    create_introduction
    @controller.instance_variable_set( '@introduction', @introduction )
    expected = "You've graciously accepted introductions with #{@introduction.character.name} and can now call upon them as one of your contacts."
    assert_equal expected, @controller.send(:acceptance_message)
  end

  test 'refusal_message' do
    create_introduction
    @controller.instance_variable_set( '@introduction', @introduction )
    expected = "You've cooly avoided introductions with #{@introduction.character.name}, a slight which shall not go happily unnoticed."
    assert_equal expected, @controller.send(:refusal_message)
  end

  test 'return_path' do
    create_introduction
    @controller.instance_variable_set( '@introduction', @introduction )
    assert_equal facebook_character_path(@introduction.character_id), @controller.send(:return_path)
  end
  
  test 'return_path for create' do
    flexmock(@controller).should_receive(:action_name).and_return('create')
    assert_equal facebook_contacts_path, @controller.send(:return_path)
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
    
    post :create, :contact_id => '1', :signed_request => @signed_request
    assert_investigator_required
    
    put :update, :id => '1', :signed_request => @signed_request
    assert_investigator_required
    
    delete :destroy, :id => '1', :signed_request => @signed_request
    assert_investigator_required        
  end
  
  test 'routes' do
    assert_routing({:method => 'delete', :path => "/facebook/introductions/1"}, 
                   {:controller => 'facebook/introductions', :action => 'destroy', :id => '1' })
    assert_routing({:method => 'put', :path => "/facebook/introductions/1"}, 
                   {:controller => 'facebook/introductions', :action => 'update', :id => '1' })
    assert_routing({:method => 'post', :path => "/facebook/contacts/1/introductions"}, 
                   {:controller => 'facebook/introductions', :action => 'create', :contact_id => '1' })
  end  
end