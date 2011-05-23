require 'test_helper'

class Web::InvestigationsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @thread = plot_threads(:aleph_troubled_dreams)
    @assignment = assignments(:aleph_grandfathers_journal_beth)
    @prerequisite = prerequisites(:troubled_dreams_notebook)
    @investigation = investigations(:aleph_investigating)
  end
  
  def set_challenge_range(range)
    Intrigue.send(:remove_const, 'CHALLENGE_RANGE')
    Intrigue.const_set('CHALLENGE_RANGE', range)
  end

  test 'new' do
    @thread.investigations.destroy_all
    @prerequisite.update_attribute(:plot_id, @thread.plot_id)
    @controller.login!(@user)
    
    get :new, :casebook_id => @thread.id
    assert_response :success
    assert_template "web/investigations/new"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:investigation).assignments.blank?
    assert !assigns(:prerequisites).blank?
    assert !assigns(:rewards).blank?
    assert !assigns(:allies).blank?
    assert !assigns(:contacts).blank?
  
    form = { :action => web_casebook_investigations_path, :method=>"post" }
    assert_tag :tag => "form", :attributes => form
                             
    assigns(:investigation).assignments.each_with_index do |a,idx|
      assert_tag :tag => "form", 
                :descendant => {:tag => "input", :attributes => {
                    :type => "hidden", 
                    :value => a.intrigue_id,
                    :name => "investigation[assignments_attributes][#{idx}][intrigue_id]"
                }}
      assert_tag :tag => "form", 
                :descendant => {:tag => "input", :attributes => {
                    :type => "hidden", 
                    :value => @user.investigator.id,
                    :name => "investigation[assignments_attributes][#{idx}][investigator_id]"
                }}
      assert_tag :tag => "form",
                :descendant => {:tag => "input", :attributes => {
                    :type => "hidden", 
                    :name => "investigation[assignments_attributes][#{idx}][ally_id]",
                    'data-field' => 'ally'
                }}
      assert_tag :tag => "form",
                :descendant => {:tag => "input", :attributes => {
                    :type => "hidden", 
                    :name => "investigation[assignments_attributes][#{idx}][contact_id]",
                    'data-field' => 'contact'
                }}   
    end
  end 
  
  test 'create' do
    @user.investigator.casebook.update_all(:status => 'available')
    @user.investigator.stats.update_all(:skill_level => 0)
    @controller.login!(@user)
    Investigation.destroy_all
    
    params = {:assignments_attributes => {}}
    @thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {:intrigue_id => intrigue.id, :investigator_id => @user.investigator_id} 
    end
    
    assert_difference ['Assignment.count'], +@thread.plot.intrigues.size do
      assert_difference ['Investigation.count','@user.investigator.investigations.active.count'], +1 do      
        post :create, :casebook_id => @thread.id, :investigation => params
        assert_response :found
        assert !assigns(:investigation).blank?
        @thread.reload
        notice = "Now investigating the #{@thread.plot.title}. After #{@thread.plot.duration} hours, you can return and attempt to solve the matter."
        assert_equal notice, flash[:notice]
        
        assert_equal 'investigating', @thread.status
        assert_equal 'active', assigns(:investigation).status
        
        assert_redirected_to web_casebook_index_path
      end
    end
  end   
  
  test 'create with moxie_speed' do
    moxie = @thread.plot.duration
    @user.investigator.casebook.update_all(:status => 'available')
    @user.investigator.update_attribute(:moxie, moxie)
    @controller.login!(@user)
    Investigation.destroy_all
    
    params = {:assignments_attributes => {}, :moxie_speed => moxie}
    @thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {:intrigue_id => intrigue.id, :investigator_id => @user.investigator_id} 
    end
    
    assert_difference ['@user.investigator.reload.moxie'], -moxie do
      assert_difference ['Investigation.count','@user.investigator.investigations.investigated.count'], +1 do      
        post :create, :casebook_id => @thread.id, :investigation => params
        assert_equal 'investigating', @thread.reload.status
        assert_equal 'investigated', assigns(:investigation).status
        assert_equal moxie, assigns(:investigation).moxie_speed
        
        assert_redirected_to edit_web_casebook_investigation_path(@thread, assigns(:investigation))
      end
    end
  end
  
  test 'create failure' do
    @user.investigator.casebook.update_all(:status => 'available')
    @controller.login!(@user)
    Investigation.destroy_all
    
    assert_no_difference ['Assignment.count','Investigation.count'] do
      post :create, :casebook_id => @thread.id, :investigation => {}
      assert_response :found
      assert !assigns(:plot_thread).blank?
      assert !flash[:error].blank?
      assert_redirected_to new_web_casebook_investigation_path(@thread)
    end      
    assert_equal 'available', @thread.reload.status
  end  
  
  test 'edit for active' do
    @investigation.update_attribute(:status, 'active')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    get :edit, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
    assert_response :success
    assert_template "web/investigations/edit"
    assert !assigns(:investigation).assignments.blank?
    assert !assigns(:assignments).blank?
    assert !assigns(:rewards).blank?
    assert !assigns(:threats).blank?
    
    assert_tag :tag => "a", :attributes => {:href => web_casebook_investigation_path(@investigation.plot_thread, @investigation),
                                            'data-method' => 'delete'}
  end
  
  test 'edit for investigated' do
    @investigation.update_attribute(:status, 'investigated')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    get :edit, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
    assert_response :success
    assert_tag :tag => "a", :attributes => {:href => complete_web_casebook_investigation_path(@investigation.plot_thread, @investigation),
                                            'data-method' => 'put'}
  end  
  
  test 'edit for completed' do
    @investigation.update_attribute(:status, 'completed')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    get :edit, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
    assert_response :success
    assert !@investigation.plot.solutions.blank?
    @investigation.plot.solutions.each do |solution|
      assert_tag :tag => "a", :attributes => {:href => solve_web_casebook_investigation_path(@investigation.plot_thread, @investigation, :solution_id => solution.id),
                                              'data-method' => 'put'}
    end
  end  
  
  test 'complete success' do
    set_challenge_range(0)
    @investigation.update_attribute(:status, 'investigated')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    @investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, -1000) }
  
    flexmock(Investigation).new_instances.should_receive(:do_intrigue_challenges).and_return(true)
    investigator = @investigation.investigator
    assert_difference ['investigator.investigations.investigated.count'], -1 do
      assert_difference ['investigator.investigations.completed.count'], +1 do      
        put :complete, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
        assert_response :found
        assert !flash[:notice].blank?
        assert_redirected_to edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
        assert_equal 'completed', @investigation.reload.status
        investigator.reload
      end
    end
  end

  test 'complete failure' do
    set_challenge_range(1000)
    @investigation.plot_thread.update_attribute(:status, 'active')
    @investigation.update_attribute(:status, 'investigated')
    @investigation.update_attribute(:created_at, Time.now)
    @investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, 1000) }
    @user.investigator.stats.update_all(:skill_level => 0)
        
    @controller.login!(@user)
    investigator = @investigation.investigator
    
    flexmock(Investigation).new_instances.should_receive(:do_intrigue_challenges).and_return(false)
    assert_difference ['investigator.investigations.investigated.count'], -1 do
      assert_difference ['investigator.investigations.unsolved.count'], +1 do      
        put :complete, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
        assert_response :found
        assert !flash[:error].blank?
        assert_redirected_to web_casebook_path( @investigation.plot_thread_id )
        assert_equal 'unsolved', @investigation.reload.status
        investigator.reload
      end
    end
  end
  
  test 'solve' do
    @investigation.update_attribute(:status, 'completed')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    solution = @investigation.plot.solutions.first
    investigator = @investigation.investigator
    assert_difference ['investigator.investigations.completed.count'], -1 do
      assert_difference ['investigator.investigations.solved.count'], +1 do      
        put :solve, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id, :solution_id => solution.id
        assert_response :found
        assert !assigns(:investigation).blank?
        assert !assigns(:solution).blank?
        assert !flash[:notice].blank?
        assert_equal 'solved', @investigation.reload.status
        assert_equal solution.id, @investigation.plot_thread.solution_id
        investigator.reload
        assert_redirected_to web_casebook_investigation_path( @investigation.plot_thread_id )
      end
    end    
  end
  
  test 'solve failure' do 
    @investigation.update_attribute(:status, 'completed')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    investigator = @investigation.investigator
    assert_no_difference ['investigator.investigations.completed.count','investigator.investigations.solved.count'] do
      put :solve, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id, :solution_id => '0'
      assert_response :found
      assert !assigns(:investigation).blank?
      assert !flash[:error].blank?
      assert_equal 'completed', @investigation.reload.status
      investigator.reload
      assert_redirected_to edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
    end
  end
  
  test 'destroy' do
    @investigation.update_attribute(:status, 'active')
    @investigation.update_attribute(:created_at, Time.now)
    @controller.login!(@user)
    
    assert_difference 'Investigation.count', -1 do
      delete :destroy, :casebook_id => @investigation.plot_thread_id, :id => @investigation.id
      assert_response :found
      assert !assigns(:investigation).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_casebook_index_path
    end    
  end
  
  test 'find_for_edit' do
    thread = @investigation.plot_thread
    assert_nil @controller.send(:find_for_edit, nil)
    assert_nil @controller.send(:find_for_edit, 0)
    
    @controller.instance_variable_set(:@plot_thread, thread)
    assert_nil @controller.send(:find_for_edit, 0)
  
    assert_difference ['thread.investigations.ready.count'], +1 do
      assert_difference ["thread.investigations.where(:status => 'active').count"], -1 do
        assert_equal @investigation, @controller.send(:find_for_edit, @investigation.id)
      end
    end
    
    assert_equal @investigation, @controller.send(:find_for_edit, @investigation.id)
    
    @investigation.update_attribute(:status, 'investigated')
    assert_equal @investigation, @controller.send(:find_for_edit, @investigation.id)
  end
   
  test 'routes' do
    assert_routing("/web/casebook/1/investigations/new", { :controller => 'web/investigations', :action => 'new', :casebook_id => '1' })
    assert_routing("/web/casebook/1/investigations/1", { :controller => 'web/investigations', :action => 'show', :id => '1', :casebook_id => '1' })
    assert_routing("/web/casebook/1/investigations/1/edit", { :controller => 'web/investigations', :action => 'edit', :id => '1', :casebook_id => '1' })
    assert_routing({:method => 'put', :path => "/web/casebook/1/investigations/1/complete"}, 
                  {:controller => 'web/investigations', :action => 'complete', :id => '1', :casebook_id => '1' })
    assert_routing({:method => 'put', :path => "/web/casebook/1/investigations/1/solve"}, 
                  {:controller => 'web/investigations', :action => 'solve', :id => '1', :casebook_id => '1' })                  
    assert_routing({:method => 'put', :path => "/web/casebook/1/investigations/1/hasten"}, 
                  {:controller => 'web/investigations', :action => 'hasten', :id => '1', :casebook_id => '1' })                  
  
    assert_routing({:method => 'post', :path => "/web/casebook/1/investigations"}, 
                  {:controller => 'web/investigations', :action => 'create', :casebook_id => '1' })
    assert_routing({:method => 'delete', :path => "/web/casebook/1/investigations/1"}, 
                  {:controller => 'web/investigations', :action => 'destroy', :id => '1', :casebook_id => '1' })
  end   
end