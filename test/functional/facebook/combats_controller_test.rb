require 'test_helper'

class Facebook::CombatsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @monster = monsters(:acolyte)
    @combat = Combat.new(:investigator => @investigator, 
                         :monster => @monster)
    flexmock(@controller).should_receive(:award_daily_income)
    init_signed_request
  end
  
  test 'new' do
    get :new, :monster_id => @monster.id, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/combats/new"
    assert !assigns(:location).blank?
    assert !assigns(:monster).blank?
    assert !assigns(:combat).blank? 
  end  
  
  test 'new for js' do
    get :new, :monster_id => @monster.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['html'].blank?
  end  
  
  test 'new with effections' do
    possession = @user.investigator.possessions.create!( :item => items(:abraxas_stone), :origin => 'gift' ) 
    possession.send(:create_effects)
    effects(:abraxas_stone_enhance_defense).effections.update_all(:begins_at => Time.now - 1.hour)
    
    get :new, :monster_id => @monster.id, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/combats/new"
    assert !assigns(:combat).blank?
    assert !assigns(:effections).blank?
  end
  
  test 'create combat success' do
    flexmock(Combat).new_instances.should_receive(:succeeded?).and_return(true)
    
    assert_difference ['Combat.count'], +1 do
      post :create, :monster_id => @monster.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:location).blank?
      assert !assigns(:monster).blank?
      assert !assigns(:combat).blank?
      assert !flash[:notice].blank?
    end
    assert_redirected_to facebook_location_path
  end  
  
  test 'create combat success for js' do
    flexmock(Combat).new_instances.should_receive(:succeeded?).and_return(true)
    
    assert_difference ['Combat.count'], +1 do
      post :create, :monster_id => @monster.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:location).blank?
      assert !assigns(:monster).blank?
      assert !assigns(:combat).blank?
      assert_js_response
      json = JSON.parse(@response.body)
      assert_equal 'redirect', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
      assert !json['html'].blank?
      assert !json['to'].blank?
    end
  end  
  
  test 'create combat failure' do
    flexmock(Combat).new_instances.should_receive(:succeeded?).and_return(false)
    flexmock(Investigator).new_instances.should_receive(:attacks).and_return(0)
    
    assert_no_difference '@user.reload.investigator.funds' do
      assert_difference ['Combat.count'], +1 do
        post :create, :monster_id => @monster.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:location).blank?
        assert !assigns(:monster).blank?
        assert !assigns(:combat).blank?
        assert !flash[:error].blank?
        assert_redirected_to facebook_location_path
      end
    end
  end  
  
  test 'new_html' do
    opts = {:layout => false, :template => "facebook/combats/new.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:new_html)
  end
  
  test 'show_html' do
    opts = {:layout => false, :template => "facebook/combats/show.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:show_html)
  end
  
  test 'failure_message' do
    @combat.logs = []
    @combat.logs << "failed"
    @combat.logs << "madness"
    @controller.instance_variable_set( '@combat', @combat )
    assert_equal "You lost the battle and failed madness", @controller.send(:failure_message)
  end  
  
  test 'success_message' do
    @combat.logs = []
    @combat.logs << "success"
    @combat.logs << "madness"
    @controller.instance_variable_set( '@combat', @combat )
    @controller.instance_variable_set( '@monster', @monster )
    expected = "success madness You earned your bounty of £#{@monster.bounty}."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'return_path' do
    assert_equal facebook_location_path, @controller.send(:return_path)
  end
  
  test 'require_user' do
    get :new, :monster_id => 1
    assert_user_required
    
    post :create, :monster_id => 1
    assert_user_required
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :new, :monster_id => 1, :signed_request => @signed_request
    assert_investigator_required
    
    post :create, :monster_id => 1, :signed_request => @signed_request
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing("/facebook/monsters/1/combats/new", { :controller => 'facebook/combats', :action => 'new', :monster_id => '1' })
    assert_routing({:method => 'post', :path => "/facebook/monsters/1/combats"}, 
                  {:controller => 'facebook/combats', :action => 'create', :monster_id => '1' })
    
  end
end