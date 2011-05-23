require 'test_helper'

class Facebook::EffortsControllerTest < ActionController::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @tasking = taskings(:miskatonic_university_university_lecture)
    
    init_signed_request
  end
  
  def set_investigator_for_tasking
    @tasking.update_attribute(:level, 1)
    @investigator.update_attribute(:location_id, @tasking.owner_id)
  end
  
  test 'create' do
    set_investigator_for_tasking
    
    assert_difference '@investigator.efforts.count', +1 do
      post :create, :tasking_id => @tasking.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:effort).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_location_path
    end
  end
  
  test 'create for js' do
    set_investigator_for_tasking
    
    assert_difference '@investigator.efforts.count', +1 do
      post :create, :tasking_id => @tasking.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:effort).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end  
  
  test 'create failure' do
    @investigator.update_attribute(:location_id, @tasking.owner_id)
    
    assert_no_difference '@investigator.efforts.count' do
      post :create, :tasking_id => @tasking.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:effort).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_location_path
    end
  end
    
  test 'failure_message' do
    effort = Effort.new
    effort.errors[:base] << 'test1'
    effort.errors[:base] << 'test2'
    @controller.instance_variable_set( '@effort', effort )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'success_message rewarded' do
    effort = Effort.new
    flexmock(effort).should_receive(:succeeded?).and_return(true).once
    flexmock(@controller).should_receive(:rewarded_message).and_return('test').once
    @controller.instance_variable_set( '@effort', effort )
    assert_equal 'test', @controller.send(:success_message)
  end
  
  test 'success_message unrewarded' do
    effort = Effort.new
    flexmock(effort).should_receive(:succeeded?).and_return(false).once
    flexmock(@controller).should_receive(:unrewarded_message).and_return('test').once
    @controller.instance_variable_set( '@effort', effort )
    assert_equal 'test', @controller.send(:success_message)
  end  
  
  test 'rewarded_message' do
    @controller.instance_variable_set( '@tasking', @tasking )
    expected = "You completed the task #{@tasking.task.name} and earned #{@tasking.reward_name}"
    assert_equal expected, @controller.send(:rewarded_message)
  end
  
  test 'unrewarded_message' do
    @controller.instance_variable_set( '@tasking', @tasking )
    expected = "You failed to complete the task #{@tasking.task.name}, earning nothing"
    assert_equal expected, @controller.send(:unrewarded_message)
  end  
  
  test 'return_path' do
    assert_equal facebook_location_path, @controller.send(:return_path)
  end  
  
  test 'require_user' do
    post :create, :tasking_id => '1'
    assert_user_required
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    post :create, :tasking_id => '1', :signed_request => @signed_request
    assert_investigator_required
  end    
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/facebook/location/taskings/1/efforts"}, 
                   {:controller => 'facebook/efforts', :action => 'create', :tasking_id => '1' })
  end  
end