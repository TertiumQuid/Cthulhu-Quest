require 'test_helper'

class Facebook::HealingControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = @user.investigator
    @medical = items(:first_aid_kit)
    @possession = possessions(:aleph_first_aid_kit)
    flexmock(@controller).should_receive(:recover_daily_wounds)
    
    init_signed_request
  end
  
  test 'show medical' do
    get :show, :investigator_id => @investigator.id, :signed_request => @signed_request, :kind => 'medical'
    assert_response :success
    assert !assigns(:items).blank?
    assert_response :success
    assert_template "facebook/healing/show"
  end  
  
  test 'show spirit' do
    get :show, :investigator_id => @investigator.id, :signed_request => @signed_request, :kind => 'spirit'
    assert_response :success
    assert !assigns(:items).blank?
    assert_response :success
    assert_template "facebook/healing/show"
  end  
  
  test 'show medical for js' do
    get :show, :investigator_id => @investigator.id, :signed_request => @signed_request, :kind => 'medical', :format => 'js'
    assert_response :success
    assert !assigns(:items).blank?
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['html'].blank?
  end
  
  test 'show medical for another' do
    other_investigator = investigators(:beth_pi)
    get :show, :investigator_id => other_investigator.id, :signed_request => @signed_request, :kind => 'medical'
    assert_response :success
    assert !assigns(:items).blank?
    assert_equal other_investigator, assigns(:investigator)
  end
  
  test 'show spirit for another' do
    other_investigator = investigators(:beth_pi)
    get :show, :investigator_id => other_investigator.id, :signed_request => @signed_request, :kind => 'spirit'
    assert_response :success
    assert !assigns(:items).blank?
    assert_equal other_investigator, assigns(:investigator)
  end  
    
  test 'medical healing for self' do
    @investigator.update_attribute(:wounds, 1)
  
    assert_difference ['@investigator.wounds','@possession.uses_count'], -1 do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'medical'
      assert_response :found
      assert assigns(:investigator).blank?
      assert !assigns(:possession).blank?
      assert !flash[:notice].blank?
      assert_redirected_to edit_facebook_investigator_path
      @investigator.reload
      @possession.reload
    end
  end  
  
  test 'medical healing for self for js' do
    @investigator.update_attribute(:wounds, 1)
  
    assert_difference ['@investigator.wounds','@possession.uses_count'], -1 do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'medical', :format => 'js'
      assert_response :success
      assert assigns(:investigator).blank?
      assert !assigns(:possession).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['json'].blank?
      assert json['html'].blank?      
      @investigator.reload
      @possession.reload
    end
  end  
  
  test 'medical healing for another' do
    friend = investigators(:gimel_pi)
    friend.update_attribute(:wounds, 2)
    @investigator.update_attribute(:wounds, 1)
    
    assert_difference ['friend.wounds'], -2 do
      assert_difference ['@investigator.wounds','@possession.uses_count'], -1 do
        post :create, :investigator_id => friend.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'medical'
        assert_response :found
        assert !flash[:notice].blank?
        assert !assigns(:possession).blank?
        assert !assigns(:investigator).blank?
        assert_redirected_to facebook_investigator_path(friend)
        @investigator.reload
        friend.reload
        @possession.reload
      end
    end
  end  
  
  test 'medical healing failure' do
    @investigator.update_attribute(:wounds, 1)
    @possession.destroy
    
    assert_no_difference ['@investigator.wounds'] do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'medical'
      assert_response :found
      assert assigns(:investigator).blank?
      assert assigns(:possession).blank?
      assert !flash[:error].blank?
      assert_redirected_to edit_facebook_investigator_path
      @investigator.reload
    end    
  end  
  
  test 'medical healing failure for js' do
    @investigator.update_attribute(:wounds, 1)
    @possession.destroy
    
    assert_no_difference ['@investigator.wounds'] do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'medical', :format => 'js'
      assert_response :success
      assert assigns(:possession).blank?
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert json['json'].blank?
      assert json['html'].blank?
      @investigator.reload
    end    
  end  

  test 'spirits healing for self' do
    @investigator.update_attribute(:madness, 1)
    @possession = possessions(:aleph_dark_rum)
    
    assert_difference ['@investigator.madness','@possession.uses_count'], -1 do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'spirit'
      assert_response :found
      assert assigns(:investigator).blank?
      assert !assigns(:possession).blank?
      assert !flash[:notice].blank?
      assert_redirected_to edit_facebook_investigator_path
      @investigator.reload
      @possession.reload
    end
  end
  
  test 'spirits healing failure' do
    @investigator.update_attribute(:madness, 1)
    
    assert_no_difference ['@investigator.madness'] do
      post :create, :investigator_id => @investigator.id, :id => @possession.id, :signed_request => @signed_request, :kind => 'spirit'
      assert_response :found
      assert assigns(:investigator).blank?
      assert assigns(:possession).blank?
      assert !flash[:error].blank?
      assert_redirected_to edit_facebook_investigator_path
      @investigator.reload
    end    
  end
        
  test 'show_title' do
    assert_equal 'Administer Medical Treatment', @controller.send(:show_title)
    
    @controller.params[:kind] = 'medical'
    assert_equal 'Administer Medical Treatment', @controller.send(:show_title)
    
    @controller.params[:kind] = 'spirit'
    assert_equal 'Administer Calming Drink', @controller.send(:show_title)
  end
  
  test 'create_title' do
    assert_equal 'Treated Wounds', @controller.send(:create_title)
    
    @controller.params[:kind] = 'medical'
    assert_equal 'Treated Wounds', @controller.send(:create_title)
    
    @controller.params[:kind] = 'spirit'
    assert_equal 'Becalmed a Troubled Mind', @controller.send(:create_title)
  end  
  
  test 'success?' do
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_equal true, @controller.send(:success?)
    
    @user.investigator.errors[:base] << 'test2'
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_equal false, @controller.send(:success?)
  end
  
  test 'return_path for self' do
    flexmock(@controller).should_receive(:healing_self?).and_return(true)
    assert_equal edit_facebook_investigator_path, @controller.send(:return_path)
  end
  
  test 'return_path for another' do
    flexmock(@controller).should_receive(:healing_self?).and_return(false)
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_equal facebook_investigator_path(@user.investigator), @controller.send(:return_path)
  end  
  
  test 'failure_message' do
    assert_equal "Could not find item among your possessions", @controller.send(:failure_message)
  end  
  
  test 'medical success_message for self' do
    flexmock(@controller).should_receive(:healing_self?).and_return(true)
    expected = "You treat your wounds with the tools of modern medical science."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'medical success_message for another' do
    flexmock(@controller).should_receive(:healing_self?).and_return(false)
    @controller.instance_variable_set( '@investigator', @user.investigator )
    expected = "You meet with #{@user.investigator.name} and treat each other's wounds."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'spirit success_message for self' do
    flexmock(@controller).should_receive(:healing_self?).and_return(true)
    @controller.params[:kind] = 'spirit'
    expected = "You sip until your hands steady and your mind calms, finding a much-needed tranquility in the still waters of a stiff drink."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'spirit success_message for another' do
    flexmock(@controller).should_receive(:healing_self?).and_return(false)
    @controller.params[:kind] = 'spirit'
    @controller.instance_variable_set( '@investigator', @user.investigator )
    expected = "You meet with #{@user.investigator.name} and find that sharing a drink regroups the mind and leaves you becalmed."
    assert_equal expected, @controller.send(:success_message)
  end    
  
  test 'healing_self?' do
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    
    @controller.params[:investigator_id] = nil
    assert_equal false, @controller.send(:healing_self?)
    
    @controller.params[:investigator_id] = 1
    assert_equal false, @controller.send(:healing_self?)    
    
    @controller.params[:investigator_id] = @user.investigator.id
    assert_equal true, @controller.send(:healing_self?)    
  end
  
  test 'investigator_status for medical' do
    @controller.params[:kind] = 'medical'
    @user.investigator.update_attribute(:wounds, 2)
    
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    flexmock(@controller).should_receive(:healing_self?).and_return(true).once
    assert_equal @user.investigator.wound_status, @controller.send(:investigator_status)
    
    @controller.instance_variable_set( '@investigator', @user.investigator )
    flexmock(@controller).should_receive(:healing_self?).and_return(false).once
    assert_equal @investigator.wound_status, @controller.send(:investigator_status)
  end

  test 'investigator_status for spirits' do
    @controller.params[:kind] = 'spirit'
    @user.investigator.update_attribute(:madness, 2)
    
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    flexmock(@controller).should_receive(:healing_self?).and_return(true).once
    assert_equal @user.investigator.madness_status, @controller.send(:investigator_status)
    
    @controller.instance_variable_set( '@investigator', @user.investigator )
    flexmock(@controller).should_receive(:healing_self?).and_return(false).once
    assert_equal @investigator.madness_status, @controller.send(:investigator_status)
  end

  
  test 'item_list' do
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    
    @controller.params[:kind] = 'medical'
    assert_equal @user.investigator.possessions.items.medical.order('item_name'), @controller.send(:item_list)
    
    @controller.params[:kind] = 'spirit'
    assert_equal @user.investigator.possessions.items.spirit.order('item_name'), @controller.send(:item_list)
  end 
  
  test 'item' do
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    
    @controller.params[:kind] = 'medical'
    @controller.params[:id] = possessions(:aleph_first_aid_kit).id
    assert_equal possessions(:aleph_first_aid_kit), @controller.send(:item)
    
    @controller.params[:kind] = 'spirit'
    @controller.params[:id] = possessions(:aleph_dark_rum).id
    assert_equal possessions(:aleph_dark_rum), @controller.send(:item)
  end   
  
  test 'require_user' do
    get :show, :investigator_id => '1', :kind => 'medical'
    assert_user_required
        
    post :create, :investigator_id => '1', :kind => 'medical'
    assert_user_required
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :show, :investigator_id => '1', :signed_request => @signed_request, :kind => 'medical'
    assert_investigator_required
        
    post :create, :investigator_id => '1', :signed_request => @signed_request, :kind => 'medical'
    assert_investigator_required
  end    
  
  test 'routes' do
    assert_routing("/facebook/investigators/1/heal", { :controller => 'facebook/healing', :action => 'show', :investigator_id => '1', :kind => 'medical' })    
    assert_routing("/facebook/investigators/1/becalm", { :controller => 'facebook/healing', :action => 'show', :investigator_id => '1', :kind => 'spirit' })        
    assert_routing({:method => 'post', :path => "/facebook/investigators/1/heal"}, 
                   {:controller => 'facebook/healing', :action => 'create', :investigator_id => '1', :kind => 'medical' })
    assert_routing({:method => 'post', :path => "/facebook/investigators/1/becalm"}, 
                   {:controller => 'facebook/healing', :action => 'create', :investigator_id => '1', :kind => 'spirit' })
  end  
end