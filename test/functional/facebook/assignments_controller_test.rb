require 'test_helper'

class Facebook::AssignmentsControllerTest < ActionController::TestCase
  def setup
    @user = users(:beth)
    @assignment = assignments(:aleph_grandfathers_journal_beth)
    init_signed_request(@user)
  end  
  
  test 'update accepted' do
    @assignment.update_attribute(:status, 'requested')
    assert_equal 'requested', @assignment.status, 'requested assignment required'
    put :update, :id => @assignment.id, :assignment => {:status => 'accepted'}, :signed_request => @signed_request
    
    assert_response :found
    assert !assigns(:assignment).blank?
    assert !flash[:notice].blank?
    assert_equal 'accepted', @assignment.reload.status
    assert_redirected_to facebook_casebook_index_path
  end  
  
  test 'update refused' do
    @assignment.update_attribute(:status, 'requested')
    put :update, :id => @assignment.id, :assignment => {:status => 'refused'}, :signed_request => @signed_request
    
    assert_response :found
    assert !assigns(:assignment).blank?
    assert !flash[:notice].blank?
    assert_equal 'refused', @assignment.reload.status
    assert_redirected_to facebook_casebook_index_path
  end  
  
  test 'update failure' do
    @assignment.update_attribute(:status, 'requested')
    put :update, :id => @assignment.id, :assignment => {:status => 'bad'}, :signed_request => @signed_request
    
    assert_response :found
    assert !assigns(:assignment).blank?
    assert !flash[:error].blank?
    assert_equal 'requested', @assignment.reload.status
    assert_redirected_to facebook_casebook_index_path
  end
    
  test 'update for js' do
    assert_equal 'requested', @assignment.status, 'requested assignment required'
    put :update, :id => @assignment.id, :assignment => {:status => 'accepted'}, :signed_request => @signed_request, :format => 'js'
    
    assert !assigns(:assignment).blank?
    json = JSON.parse(@response.body)
    assert_js_response
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['message'].blank?
  end  
  
  test 'failure_message' do
    @assignment.errors[:base] << 'test1'
    @assignment.errors[:base] << 'test2'
    @controller.instance_variable_set( '@assignment', @assignment )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'accepted_message' do
    @controller.instance_variable_set( '@assignment', @assignment )
    expected = "You're now helping your ally to investigate an intrigue, and #{@assignment.intrigue.title}"
    assert_equal expected, @controller.send(:accepted_message)
  end

  test 'declined_message' do
    @controller.instance_variable_set( '@assignment', @assignment )
    expected = "You declined to help your ally #{@assignment.intrigue.title}"
    assert_equal expected, @controller.send(:declined_message)
  end
  
  test 'return_path' do
    assert_equal facebook_casebook_index_path, @controller.send(:return_path)
  end
    
  test 'require_user' do
    put :update, :id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    
    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required   
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/facebook/assignments/1"}, 
                   {:controller => 'facebook/assignments', :action => 'update', :id => "1" })
  end  
end