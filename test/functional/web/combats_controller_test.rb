require 'test_helper'

class Web::CombatsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @monster = monsters(:acolyte)
  end
  
  test 'new' do
    @controller.login!(@user)
    get :new, :monster_id => @monster.id
    assert_response :success
    assert_template "web/combats/new"
    assert !assigns(:location).blank?
    assert !assigns(:monster).blank?
    assert !assigns(:combat).blank?
    
    assert_tag :tag => "a", :attributes => {:href => "/web/monsters/#{@monster.id}/combats",
                                            'data-method' => 'post'}    
  end
  
  test 'new without combat_fit?' do  
    flexmock(@controller).should_receive(:recover_daily_wounds)
    @user.investigator.update_attribute(:wounds, @user.investigator.maximum_wounds)
    @controller.login!(@user)
    get :new, :monster_id => @monster.id   
    assert_response :success
    assert_template "web/combats/new"
    assert_no_tag :tag => "a", :attributes => {:href => "/web/monsters/#{@monster.id}/combats"}    
  end
  
  test 'create with success' do
    @controller.login!(@user)
    flexmock(Combat).new_instances.should_receive(:succeeded?).and_return(true)
    assert_difference ['Combat.count'], +1 do
      post :create, :monster_id => @monster.id
      assert !assigns(:location).blank?
      assert !assigns(:monster).blank?
      assert !assigns(:combat).blank?
      assert !flash[:notice].blank?
    end
    assert_redirected_to web_location_path(@user.investigator.location)
  end
  
  test 'create with failure' do
    @controller.login!(@user)
    flexmock(Combat).new_instances.should_receive(:succeeded?).and_return(false)
    assert_no_difference '@user.reload.investigator.funds' do
      assert_difference ['Combat.count'], +1 do
        post :create, :monster_id => @monster.id
        assert !assigns(:location).blank?
        assert !assigns(:monster).blank?
        assert !assigns(:combat).blank?
        assert !flash[:notice].blank?
      end
    end
    assert_redirected_to web_location_path(@user.investigator.location)
  end  
  
  test 'require_user' do
    get :new, :monster_id => 1
    assert_user_required
        
    post :create, :monster_id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    get :new, :monster_id => 1
    assert_investigator_required  
    
    post :create, :monster_id => 1
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing("/web/monsters/1/combats/new", { :controller => 'web/combats', :action => 'new', :monster_id => '1' })
    assert_routing({:method => 'post', :path => "/web/monsters/1/combats"}, 
                  {:controller => 'web/combats', :action => 'create', :monster_id => '1' })
    
  end  
end