require 'test_helper'

class Web::AssignmentsControllerTest < ActionController::TestCase
  def setup
    @user = users(:beth)
    @assignment = assignments(:aleph_grandfathers_journal_beth)
  end
  
  test 'edit active assignment' do
    @assignment.update_attribute(:status, 'requested')
    @assignment.investigation.update_attribute(:status, 'active')
    @controller.login!( @user)
    
    get :edit, :id => @assignment.id
    assert_response :success
    assert_template "web/assignments/edit"
    assert !assigns(:assignment).blank?
    assert !assigns(:investigation).blank?
    assert !assigns(:plot).blank?

    assert_tag :tag => "form", :attributes => { :action => web_assignment_path(@assignment, 'assignment[status]' => 'refused') }
    assert_tag :tag => "form", :attributes => { :action => web_assignment_path(@assignment, 'assignment[status]' => 'accepted') }
  end

  test 'edit resolved assignment' do
    @assignment.investigation.update_attribute(:status, 'solved')
    @controller.login!( @user )
    
    get :edit, :id => @assignment.id
  end
  
  test 'update accepted' do
    @controller.login!( @user )
    assert_equal 'requested', @assignment.status, 'requested assignment required'
    put :update, :id => @assignment.id, :assignment => {:status => 'accepted'}
    assert_response :found
    assert !assigns(:assignment).blank?
    assert assigns(:assignment).errors.empty?
    assert_equal 'accepted', @assignment.reload.status
    assert_equal "You're now helping to investigate this plot", flash[:notice]
    assert_redirected_to web_casebook_index_path
  end
  
  test 'update refused' do
    @controller.login!( @user )
    assert_equal 'requested', @assignment.status, 'requested assignment required'
    put :update, :id => @assignment.id, :assignment => {:status => 'refused'}
    assert_response :found
    assert !assigns(:assignment).blank?
    assert assigns(:assignment).errors.empty?
    assert_equal 'refused', @assignment.reload.status
    assert_equal "You've declined to help investigate this plot", flash[:notice]
    assert_redirected_to web_casebook_index_path
  end
  
  test 'require_user' do
    get :edit, :id => 1
    assert_user_required 
    
    put :update, :id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!( @user )  
    
    get :edit, :id => 1
    assert_investigator_required
        
    put :update, :id => 1
    assert_investigator_required   
  end  
  
  test 'routes' do
    assert_routing("/web/assignments/1/edit", { :controller => 'web/assignments', :action => 'edit', :id => "1" })
    assert_routing({:method => 'put', :path => "/web/assignments/1"}, 
                   {:controller => 'web/assignments', :action => 'update', :id => "1" })
  end  
end