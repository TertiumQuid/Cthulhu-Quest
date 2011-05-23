require 'test_helper'

class Facebook::InvestigationsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @plot_thread = plot_threads(:aleph_troubled_dreams)
    @investigation = Investigation.new
    init_signed_request
  end
  
  def set_challenge_range(range)
    Intrigue.send(:remove_const, 'CHALLENGE_RANGE')
    Intrigue.const_set('CHALLENGE_RANGE', range)
  end
    
  def params_for_create
    @user.investigator.casebook.update_all(:status => 'available')
    @user.investigator.stats.update_all(:skill_level => 0)
    Investigation.destroy_all
    
    params = {:assignments_attributes => {}}
    @plot_thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {:intrigue_id => intrigue.id, :investigator_id => @user.investigator_id} 
    end
    return params
  end
  
  test 'new' do
    get :new, :casebook_id => @plot_thread.id, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/investigations/new"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:investigation).blank?
    assert !assigns(:allies).blank?
    assert !assigns(:contacts).blank?
  end  
  
  test 'new with previous successful assignments' do
    @user.destroy
    init_signed_request( users(:beth) )
    investigation = investigations(:beth_zohar_investigating)
    investigation.destroy
    
    get :new, :casebook_id => investigation.plot_thread_id, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/investigations/new"
    assert !assigns(:plot_thread).blank?
    assert !assigns(:investigation).blank?
    assert !assigns(:completed_assignments).blank?
  end  
  
  test 'new for js' do
    get :new, :casebook_id => @plot_thread.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['html'].blank?
  end  
  
  test 'create' do
    params = params_for_create
    assert_difference ['Assignment.count'], +@plot_thread.plot.intrigues.size do
      assert_difference ['Investigation.count','@user.investigator.investigations.active.count'], +1 do      
        post :create, :casebook_id => @plot_thread.id, :investigation => params, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:plot_thread).blank?
        assert !assigns(:investigation).blank?
        
        @plot_thread.reload
        notice = "Now investigating #{@plot_thread.plot.title}. After #{@plot_thread.plot.duration} hours, you can return and attempt to solve the matter. In the meanwhile, any allies you've assigned will have a chance to offer their help."
        assert_equal notice, flash[:notice]
        
        assert_equal 'investigating', @plot_thread.status
        assert_equal 'active', assigns(:investigation).status
        
        assert_redirected_to facebook_casebook_index_path
      end
    end
  end  
  
  test 'create for js' do
    params = params_for_create
    
    assert_difference ['Assignment.count'], +@plot_thread.plot.intrigues.size do
      assert_difference ['Investigation.count','@user.investigator.investigations.active.count'], +1 do      
        post :create, :casebook_id => @plot_thread.id, :investigation => params, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        assert !assigns(:plot_thread).blank?
        assert !assigns(:investigation).blank?
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
        @plot_thread.reload        
        assert_equal 'investigating', @plot_thread.status
        assert_equal 'active', assigns(:investigation).status
      end
    end
  end 
  
  test 'create with moxie' do
    moxie = @plot_thread.plot.duration
    params = params_for_create
    params[:moxie_speed] = moxie
    @user.investigator.update_attribute(:moxie, moxie)

    assert_difference ['@user.investigator.moxie'], -moxie do    
      assert_difference ['Assignment.count'], +@plot_thread.plot.intrigues.size do
        assert_difference ['Investigation.count','@user.investigator.investigations.investigated.count'], +1 do      
          post :create, :casebook_id => @plot_thread.id, :investigation => params, :signed_request => @signed_request
          assert !assigns(:plot_thread).blank?
          assert !assigns(:investigation).blank?
          @plot_thread.reload
          @user.reload
          assert_equal 'investigating', @plot_thread.status
          assert_equal 'investigated', assigns(:investigation).status
        end
      end    
    end
  end
  
  test 'update complete success' do
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'investigated')
    investigation.update_attribute(:created_at, Time.now)
    
    set_challenge_range(1)
    investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, 0) }
    flexmock(Assignment).new_instances.should_receive(:random).and_return(0)
    
    assert_difference ['@user.investigator.investigations.investigated.count'], -1 do
      assert_difference ['@user.investigator.investigations.completed.count'], +1 do      
        put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :signed_request => @signed_request
        assert_response :found
        assert !flash[:notice].blank?
        assert_redirected_to facebook_casebook_index_path
        assert_equal 'completed', investigation.reload.status
        @user.investigator.reload
      end
    end
  end  
  
  test 'update complete for js' do
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'investigated')
    investigation.update_attribute(:created_at, Time.now)
    
    set_challenge_range(1)
    investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, 0) }
    
    put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['html'].blank?
    assert !json['to'].blank?
    assert !json['message'].blank?
  end  
  
  test 'update unsolved' do
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'investigated')
    investigation.update_attribute(:created_at, Time.now)
    
    set_challenge_range(10000)
    investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, 100) }
        
    assert_difference ['@user.investigator.investigations.investigated.count'], -1 do
      assert_difference ['@user.investigator.investigations.unsolved.count'], +1 do        
        put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :signed_request => @signed_request
        assert_response :found
        assert !flash[:notice].blank?
        assert_redirected_to facebook_casebook_index_path
        assert_equal 'unsolved', investigation.reload.status
        @user.investigator.reload
      end
    end
  end
  
  test 'update unsolved for js' do
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'investigated')
    investigation.update_attribute(:created_at, Time.now)
    
    set_challenge_range(10000)
    investigation.plot.intrigues.each { |a| a.update_attribute(:difficulty, 100) }
        
    assert_difference ['@user.investigator.investigations.investigated.count'], -1 do
      assert_difference ['@user.investigator.investigations.unsolved.count'], +1 do        
        put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['html'].blank?
        assert !json['to'].blank?
        assert !json['message'].blank?
        assert_equal 'unsolved', investigation.reload.status
        @user.investigator.reload
      end
    end
  end  
  
  test 'update solve' do
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'completed')
    investigation.assignments.update_all(:result => 'succeeded', :status => 'accepted')
    solution = investigation.plot.solutions.first
    
    assert_difference ['@user.investigator.investigations.completed.count'], -1 do
      assert_difference ['@user.investigator.investigations.solved.count'], +1 do        
        put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :solution_id => solution.id, :signed_request => @signed_request
        assert_response :found
        assert !flash[:notice].blank?
        assert_redirected_to facebook_casebook_index_path
        
        investigation.reload
        assert_equal 'solved', investigation.status
        assert_equal solution.id, investigation.plot_thread.solution_id
        @user.investigator.reload
      end
    end    
  end
  
  test 'update solve for js' do 
    investigation = investigations(:aleph_investigating)
    investigation.update_attribute(:status, 'completed')
    investigation.assignments.update_all(:result => 'succeeded', :status => 'accepted')
    solution = investigation.plot.solutions.first
    
    assert_difference ['@user.investigator.investigations.completed.count'], -1 do
      assert_difference ['@user.investigator.investigations.solved.count'], +1 do        
        put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :solution_id => solution.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success      
        json = JSON.parse(@response.body)  
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['to'].blank?
        assert !json['message'].blank?
        assert json['html'].blank?
                
        investigation.reload
        assert_equal 'solved', investigation.status
        assert_equal solution.id, investigation.plot_thread.solution_id
        @user.investigator.reload
      end
    end 
  end
  
  test 'update with previous successful assignments' do
    @user.destroy
    init_signed_request( users(:beth) )
    investigation = investigations(:beth_zohar_investigating)
    
    put :update, :casebook_id => investigation.plot_thread_id, :id => investigation.id, :signed_request => @signed_request
    assert !assigns(:completed_assignments).blank?
    assert assigns(:completed_assignments).select{|a|a.investigation_id == investigation.id}.blank?
  end  
  
  test 'failure_message' do
    @investigation.errors[:base] << 'test1'
    @investigation.errors[:base] << 'test2'
    @controller.instance_variable_set( '@investigation', @investigation )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'success_message' do
    @investigation.status = 'active'
    @controller.instance_variable_set( '@plot_thread', @plot_thread )
    @controller.instance_variable_set( '@investigation', @investigation )
    
    expected = "Now investigating #{@plot_thread.plot.title}. After #{@plot_thread.plot.duration} hours, you can return and attempt to solve the matter. In the meanwhile, any allies you've assigned will have a chance to offer their help."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'success_message with moxie' do
    @investigation.status = 'investigated'
    @controller.instance_variable_set( '@plot_thread', @plot_thread )
    @controller.instance_variable_set( '@investigation', @investigation )
    
    expected = "Your moxie precipitates the investigation of #{@plot_thread.plot.title} toward its conclusion. You may now attempt to solve the plot."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'unsolved_message' do
    combats(:aleph_failed_acolyte).destroy
    investigation = investigations(:aleph_failed)
    failures = investigation.assignments.select{|a| !a.successful?}.map(&:intrigue).map(&:title)
    @controller.instance_variable_set( '@investigation', investigation )
    
    expected = "It was not to be. Defeated by fate and intrigue, you failed to #{failures.join(', and ')}. But don't lose heart, you can try again, and next time you'll be stronger."
    assert_equal expected, @controller.send(:unsolved_message)
  end
  
  test 'unsolved_message with combat' do
    investigation = investigations(:aleph_failed)
    failures = investigation.assignments.select{|a| !a.successful?}.map(&:intrigue).map(&:title)
    combat = investigation.assignments.map(&:combat).select{|c| !c.nil? }
    investigation.assignments.map(&:combat).inspect
    @controller.instance_variable_set( '@investigation', investigation )
    
    expected = "It was not to be. Defeated by fate and intrigue, you failed to #{failures.join(', and ')}. Furthermore, you were attacked in the course of investigation; #{combat.map(&:result)} But don't lose heart, you can try again, and next time you'll be stronger."
    assert_equal expected, @controller.send(:unsolved_message)
  end
  
  test 'advanced_message completed?' do
    combats(:aleph_failed_acolyte).destroy
    investigation = investigations(:aleph_failed)
    investigation.update_attribute(:status, 'completed')
    intrigues = investigation.assignments.map(&:intrigue).map(&:title).join(', and ')
    @controller.instance_variable_set( '@investigation', investigation )
    
    expected = "Indeed, well done! You managed to #{intrigues}. Now the intrigues have been put to rest, and you can now choose how you'd like to solve the plot."
    assert_equal expected, @controller.send(:advanced_message)
  end
  
  test 'advanced_message completed? with combat' do
    investigation = investigations(:aleph_failed)
    investigation.update_attribute(:status, 'completed')
    intrigues = investigation.assignments.map(&:intrigue).map(&:title).join(', and ')
    combat = investigation.assignments.map(&:combat).select{|c| !c.nil? }
    @controller.instance_variable_set( '@investigation', investigation )
    
    expected = "Indeed, well done! You managed to #{intrigues}. You were attacked also in the course of investigation; #{combat.map(&:result)} Now the intrigues have been put to rest, and you can now choose how you'd like to solve the plot."
    assert_equal expected, @controller.send(:advanced_message)
  end
    
  test 'advanced_message solved?' do
    investigation = investigations(:aleph_failed)
    solution = solutions(:grandfathers_journal_confronted)
    investigation.update_attribute(:status, 'solved')
    rewards = investigation.plot.rewards.map(&:reward_name).join(', and ')
    @controller.instance_variable_set( '@investigation', investigation )
    @controller.params[:solution_id] = solution.id
    
    expected = "#{investigation.plot_title} solved. You have chosen to #{solution.description} As a reward you received #{rewards}"
    assert_equal expected, @controller.send(:advanced_message)    
  end
  
  test 'return_path' do
    assert_equal facebook_casebook_index_path, @controller.send(:return_path)
  end  
  
  test 'new_html' do
    opts = {:layout => false, :template => "facebook/investigations/new.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:new_html)
  end
  
  test 'advanced_html with completed investigation' do
    opts = {:layout => false, :template => "facebook/investigations/_investigated.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    flexmock(@investigation).should_receive(:solved?).and_return(false)
    @controller.instance_variable_set( '@investigation', @investigation )
    @controller.send(:advanced_html)
  end  
  
  test 'advanced_html with solved investigation' do  
    flexmock(@controller).should_receive(:render_to_string).times(0)
    flexmock(@investigation).should_receive(:solved?).and_return(true)
    @controller.instance_variable_set( '@investigation', @investigation )
   assert_nil @controller.send(:advanced_html)
  end
  
  test 'require_user' do
    get :new, :casebook_id => 1
    assert_user_required
    
    post :create, :casebook_id => 1
    assert_user_required    
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :new, :casebook_id => 1, :signed_request => @signed_request
    assert_investigator_required
    
    post :create, :casebook_id => 1, :signed_request => @signed_request
    assert_investigator_required    
  end  
  
  test 'assignments_json' do
    investigation = investigations(:aleph_investigating)
    json = investigation.assignments.to_json(:include => :intrigue)
    @controller.instance_variable_set( '@investigation', investigation )
    assert_equal json, @controller.send(:assignments_json)
  end
  
  test 'routes' do
    assert_routing("/facebook/casebook/1/investigations/new", { :controller => 'facebook/investigations', :action => 'new', :casebook_id => '1' })    
    assert_routing({:method => 'put', :path => "/facebook/casebook/1/investigations/1"}, 
                  {:controller => 'facebook/investigations', :action => 'update', :casebook_id => '1', :id => '1' })    
    assert_routing({:method => 'post', :path => "/facebook/casebook/1/investigations"}, 
                  {:controller => 'facebook/investigations', :action => 'create', :casebook_id => '1' })
  end
end