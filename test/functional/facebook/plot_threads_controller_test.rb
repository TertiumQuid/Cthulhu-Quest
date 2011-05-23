require 'test_helper'

class Facebook::PlotThreadsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigation = investigations(:aleph_investigating)
    @thread = plot_threads(:aleph_troubled_dreams)
    @plot = plots(:hellfire_club)
    init_signed_request
  end
  
  test 'index' do
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/plot_threads/index"
    assert !assigns(:plot_threads).blank?
    assert !assigns(:investigation).blank?
    assert !assigns(:item_ids).blank?
  end
  
  test 'index with active investigation' do
    @investigation.update_attribute(:created_at, Time.now)
    @investigation.update_attribute(:status, 'active')
    @user.investigator.psychoses.create!(:insanity => insanities(:dementia))
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/plot_threads/index"
    assert !assigns(:investigation).blank?
    assert !assigns(:plot_threads).blank?
    assert !assigns(:psychoses).blank?
    assert !assigns(:item_ids).blank?
  end  
  
  test 'index with elapsed investigation' do  
    @investigation.update_attribute(:created_at, Time.now - 1.day)
    @investigation.update_attribute(:status, 'active')
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert !assigns(:investigation).blank?
    assert_equal 'investigated', assigns(:investigation).status
  end
  
  test 'index with investigated investigation' do  
    @investigation.update_attribute(:created_at, Time.now - 1.day)
    @investigation.update_attribute(:status, 'investigated')
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert !assigns(:investigation).blank?
  end 
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_template "facebook/plot_threads/index"
    assert_html_response
  end  
  
  test 'create from location' do
    @location = @plot.locations.first
    @user.investigator.update_attribute(:location_id, @location.id)
    @user.investigator.casebook.destroy_all
  
    assert_difference ['@user.investigator.casebook.count'], +1 do
      post :create, :id => @plot.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to facebook_casebook_index_path
    end
  end  
  
  test 'create from contact' do  
    contact = contacts(:aleph_henry_armitage)
    plot = plots(:malleus_maleficarum)
    
    assert_difference ['@user.investigator.casebook.count'], +1 do
      post :create, :contact_id => contact.id, :id => plot.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to facebook_casebook_index_path
    end    
  end
  
  test 'create for js' do
    @location = @plot.locations.first
    @user.investigator.update_attribute(:location_id, @location.id)
    @user.investigator.casebook.destroy_all
  
    assert_difference ['@user.investigator.casebook.count'], +1 do
      post :create, :id => @plot.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end  
  
  test 'create failure' do
    @location = @plot.locations.first
    @user.investigator.update_attribute(:location_id, @location.id)
    @plot.update_attribute(:level, 100)
    @user.investigator.casebook.destroy_all
  
    assert_no_difference ['@user.investigator.casebook.count'] do
      post :create, :id => @plot.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:error].blank?
      assert_redirected_to facebook_casebook_index_path
    end
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@plot', @plot )
    expected = "You have accepted the plot, #{@plot.title}, and may attempt to investigate it when you are duly prepared."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'failure_message' do
    @thread.errors[:base] << 'test1'
    @thread.errors[:base] << 'test2'
    @controller.instance_variable_set( '@plot_thread', @thread )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'return_path' do
    assert_equal facebook_casebook_index_path, @controller.send(:return_path)
  end  
  
  test 'init_plot' do
  end
  
  test 'require_user' do
    get :index
    assert_user_required
    
    post :create, :id => 1
    assert_user_required
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :index, :signed_request => @signed_request
    assert_investigator_required
    
    post :create, :id => 1, :signed_request => @signed_request
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing("/facebook/casebook", { :controller => 'facebook/plot_threads', :action => 'index' })
    assert_routing({:method => 'post', :path => "/facebook/contacts/1/plot_threads"}, 
                   {:controller => 'facebook/plot_threads', :action => 'create', :contact_id => '1' })
    assert_routing({:method => 'post', :path => "/facebook/location/plot_threads"}, 
                   {:controller => 'facebook/plot_threads', :action => 'create' })
    
  end  
end