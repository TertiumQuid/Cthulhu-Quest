require 'test_helper'

class Web::PlotThreadsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @thread = plot_threads(:aleph_troubled_dreams)
    @assignment = assignments(:aleph_grandfathers_journal_beth)
    @prerequisite = prerequisites(:troubled_dreams_notebook)
    @investigation = investigations(:aleph_investigating)
  end
  
  test 'index with ready investigation' do
    @controller.login!(@user)
    
    assert_difference '@user.investigator.investigations.ready.count', +1 do
      assert_difference '@user.investigator.investigations.active.count', -1 do
        get :index
      end
    end
    assert_response :success
    assert_template "web/plot_threads/index"
    assert !assigns(:ready_investigations).blank?
    assert !assigns(:plot_threads).blank?
    assert assigns(:active_investigations).blank?
    assert assigns(:assignments).blank?
    
    solve_at = edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
    assert_tag :tag => "a", :attributes => { :href => solve_at }
  end
  
  test 'index with active investigation and help' do
    @controller.login!(@user)
    @investigation.update_attribute(:created_at, Time.now)
    @investigation.update_attribute(:status, 'active')
    
    get :index
    assert_response :success
    assert_template "web/plot_threads/index"
    assert !assigns(:active_investigations).blank?
    assert !assigns(:plot_threads).blank?
    
    assert assigns(:ready_investigations).blank?
    assert assigns(:assignments).blank?
  end  
  
  test 'index with active investigation alone' do
    @controller.login!(@user)
    @investigation.update_attribute(:created_at, Time.now)
    @investigation.update_attribute(:status, 'active')
    @investigation.assignments.each do |a|
      a.update_attribute(:investigator_id, @investigation.investigator.id)
      a.update_attribute(:status, 'accepted')
    end
    
    get :index
    assert_response :success
    assert_template "web/plot_threads/index"
  end   
  
  test 'index with assignment' do  
    investigator = investigators(:beth_pi)
    @controller.login!(investigator.user)
    
    get :index
    assert_response :success
    assert_template "web/plot_threads/index"
    assert !assigns(:assignments).blank?
    
    assigns(:assignments).each do |assignment|
      assert_tag :tag => "a", :attributes => { :href => edit_web_assignment_path(assignment) }
      assert_tag :tag => "form", :attributes => { :action => web_assignment_path(assignment, 'assignment[status]' => 'refused') }
      assert_tag :tag => "form", :attributes => { :action => web_assignment_path(assignment, 'assignment[status]' => 'accepted') }
    end
  end  
  
  test 'index without plots' do
    @controller.login!(@user)
    PlotThread.destroy_all
    
    get :index
    assert_response :success
    assert_template "web/plot_threads/index"
    assert assigns(:current_plot).blank?
    assert assigns(:available_plots).blank?
    assert assigns(:ready_investigations).blank?
    assert assigns(:assignments).blank?
  end  
  
  test 'index with solved' do
    @controller.login!(@user)
    @investigation.update_attribute(:status, 'solved')
    @investigation.update_attribute(:finished_at, Time.now)
    @investigation.plot_thread.update_attribute(:status, 'solved')
    @investigation.plot_thread.update_attribute(:solution_id, Solution.first.id)
    
    get :index
    assert_response :success
    assert_template "web/plot_threads/index"
    assert !assigns(:solved_plots).blank?
    assert @response.body.include?("The Story so Far")
  end
  
  test 'show available plot thread' do
    @controller.login!(@user)
    plot_thread = @user.investigator.casebook.create!(:plot => plots(:fire_in_the_sky), :status => 'available')
    
    get :show, :id => plot_thread.id
    assert_response :success
    assert_template "web/plot_threads/show"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:prerequisites).blank?
    assert !assigns(:rewards).blank?
    
    assigns(:rewards).each do |resource|
      assert @response.body.include?("<span>#{resource.reward_name}</span>")
    end      
    assigns(:prerequisites).each do |resource|
      assert @response.body.include?("<span>#{resource.requirement_name}</span>")
    end
  end
  
  test 'show investigating plot thread' do  
    @controller.login!(@user)
    @investigation.plot_thread.update_attribute(:status, 'investigating')
    @prerequisite.update_attribute(:plot_id, @investigation.plot.id)
    get :show, :id => @investigation.plot_thread_id
    
    assert_response :success
    assert_template "web/plot_threads/show"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:prerequisites).blank?
    assert !assigns(:rewards).blank?
    assert !assigns(:threats).blank?
    
    assert_tag :tag => "a", :attributes => { :href => edit_web_casebook_investigation_path( @investigation.plot_thread, @investigation ) }
  end
  
  test 'show own solved plot thread' do
    @controller.login!(@user)
    @investigation.update_attribute(:status, 'solved')
    @investigation.update_attribute(:finished_at, Time.now)
    @investigation.plot_thread.update_attribute(:status, 'solved')
    @investigation.plot_thread.update_attribute(:solution_id, Solution.first.id)
    
    get :show, :id => @investigation.plot_thread_id
    assert_response :success
    assert_template "web/plot_threads/show"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:rewards).blank?
    assert !assigns(:solved_investigation).blank?
    assert !assigns(:threats).blank?
  end
  
  test 'create' do
    @plot = plots(:hellfire_club)
    @location = @plot.locations.first
    @user.investigator.update_attribute(:location_id, @location.id)
    @user.investigator.casebook.destroy_all
    @controller.login!(@user)
  
    assert_difference ['@user.investigator.casebook.count'], +1 do
      post :create, :id => @plot.id
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to web_casebook_index_path
    end
  end
  
  test 'create failure' do  
    @plot = plots(:hellfire_club)
    @user.investigator.update_attribute(:location_id, locations(:london).id)
    @user.investigator.casebook.destroy_all
    @controller.login!(@user)

    assert_no_difference ['@user.investigator.casebook.count'] do
      post :create, :id => @plot.id
      assert_response :found
      assert !flash[:error].blank?
      assert_redirected_to web_casebook_index_path
    end    
  end
  
  test 'require_user' do
    get :index
    assert_user_required
    
    get :show, :id => 1
    assert_user_required    
    
    post :create
    assert_user_required  
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    
    get :index
    assert_investigator_required
    
    get :show, :id => 1
    assert_investigator_required
    
    post :create
    assert_investigator_required  
  end  
  
  test 'routes' do
    assert_routing("/web/casebook", { :controller => 'web/plot_threads', :action => 'index' })
    assert_routing("/web/casebook/1", { :controller => 'web/plot_threads', :action => 'show', :id => "1" }) 
    assert_routing({:method => 'post', :path => "/web/casebook"}, 
                   {:controller => 'web/plot_threads', :action => 'create' })
    
  end  
end
