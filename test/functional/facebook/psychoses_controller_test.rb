require 'test_helper'

class Facebook::PsychosesControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @insanity = insanities(:nightmares)
    @psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    init_signed_request
  end
  
  def set_treatment_threshold(range)
    # flexmock(Psychosis).new_instances.should_receive(:treatment_threshold).and_return(range)
    Psychosis.send(:remove_const, 'TREATMENT_RANGE')
    Psychosis.const_set('TREATMENT_RANGE', range)
  end
  
  test 'update' do
    assert_difference ['@investigator.psychoses.treating.count'], +1 do
      put :update, :id => @psychosis.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:psychosis).blank?
      assert !flash[:notice].blank?
    end  
    assert @psychosis.reload.treating?
    assert_redirected_to edit_facebook_investigator_path
  end  
  
  test 'update failure' do
    @psychosis.begin_treatment!
    assert_no_difference ['@investigator.psychoses.treating.count'] do
      put :update, :id => @psychosis.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:psychosis).blank?
      assert !flash[:error].blank?
    end  
    assert_redirected_to edit_facebook_investigator_path
  end  
  
  test 'update for js' do
    assert_difference ['@investigator.psychoses.treating.count'], +1 do
      put :update, :id => @psychosis.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert_js_response
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end  
    assert @psychosis.reload.treating?
  end
  
  test 'destroy' do
    @psychosis.update_attribute(:next_treatment_at, Time.now - 1.day)
    @psychosis.update_attribute(:severity, 0)
    
    assert_difference ['@investigator.psychoses.count'], -1 do
      delete :destroy, :id => @psychosis.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:psychosis).blank?
      assert !flash[:notice].blank?
      @investigator.reload
    end  
    assert_redirected_to edit_facebook_investigator_path
  end  
  
  test 'destroy failure' do
    @psychosis.update_attribute(:next_treatment_at, Time.now - 1.day)
    set_treatment_threshold(0)
    
    assert_no_difference ['@investigator.psychoses.count'] do
      assert_difference ['@investigator.psychoses.treating.count'], -1 do
        delete :destroy, :id => @psychosis.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:psychosis).blank?
        assert !flash[:error].blank?
        @investigator.reload
      end  
    end
    assert_redirected_to edit_facebook_investigator_path
  end  
  
  test 'destroy for js' do
    @psychosis.update_attribute(:next_treatment_at, Time.now - 1.day)
    set_treatment_threshold(100000)
    
    assert_difference ['@investigator.psychoses.count'], -1 do
      delete :destroy, :id => @psychosis.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:psychosis).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['json'].blank?
      @investigator.reload
    end
  end
    
  test 'return_path' do
    edit_facebook_investigator_path
  end  
  
  test 'failure_message' do
    @psychosis.errors[:base] << 'test1'
    @psychosis.errors[:base] << 'test2'
    @controller.instance_variable_set( '@psychosis', @psychosis )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'treating_message' do
    @controller.instance_variable_set( '@psychosis', @psychosis )
    expected = "You have institutionalized yourself in the grim care of the asylum. Expect to suffer fever theorapy, potent drugs, electroshock, and behaviorist mind games as you battle the crippling condition of #{@psychosis.name}."
    assert_equal expected, @controller.send(:treating_message)
  end
  
  test 'treated_message' do
    @controller.instance_variable_set( '@psychosis', @psychosis )
    expected = "The severe treatments of the asylum physicians have traumatized away the crippling duress of your #{@psychosis.degree} #{@psychosis.name}."
    assert_equal expected, @controller.send(:treated_message)
  end  
  
  test 'untreated_message' do
    @controller.instance_variable_set( '@psychosis', @psychosis )
    expected = "The best efforts of dedicated asylum physcians was unable to cure you of the #{@psychosis.degree} #{@psychosis.name}, releasing you to the world phsycially worse for your time in the institution and mentally no better."
    assert_equal expected, @controller.send(:untreated_message)
  end
  
  test 'madness_status' do
    assert_nil @controller.send(:madness_status)
    
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    assert_equal @user.investigator.madness_status, @controller.send(:madness_status)
  end
  
  test 'require_user' do
    delete :destroy, :id => 1
    assert_user_required
    
    put :update, :id => 1
    assert_user_required    
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    delete :destroy, :id => 1, :signed_request => @signed_request
    assert_investigator_required
    
    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/facebook/psychoses/1"}, 
                   {:controller => 'facebook/psychoses', :action => 'update', :id => '1' })    
    assert_routing({:method => 'delete', :path => "/facebook/psychoses/1"}, 
                   {:controller => 'facebook/psychoses', :action => 'destroy', :id => '1' })
  end  
end