require 'test_helper'

class Web::InvestigatorsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @medical = items(:first_aid_kit)
    @investigator = investigators(:aleph_pi)
    flexmock(@controller).should_receive(:recover_daily_wounds)
  end
  
  test 'new' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    get :new
    assert_response :success
    assert_template "web/investigators/new"
    assert !assigns(:investigator).blank?
    assert !assigns(:profiles).blank?
    assert_tag :tag => "form", :attributes => { :action => web_investigators_path, :method=>"post"}
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"text",:name=>"investigator[name]"} }
    assert_tag :tag => "form", :descendant => {:tag=>"input",:attributes=>{:type=>"submit"}}
    assigns(:profiles).each do |profile|
      radio_label = "<input id=\"#{profile.name.tableize.singularize}\" name=\"investigator[profile_id]\" type=\"radio\" value=\"#{profile.id}\" />"
      income_element = "<li><span>INCOME</span><span>£#{profile.income} per day</span></li>"
      
      assert @response.body.include? radio_label
      assert @response.body.include? income_element
      profile.profile_skills.each do |s|
        skill = "<li><span>#{s.skill_name}</span><span>#{s.skill_level}</span></li>"
        assert @response.body.include? skill
      end
    end
  end
  
  test 'create' do
    assert @user.investigator.destroy, "nil investigator required"
    @user.update_attribute(:investigator_id, nil)
    @controller.login!(@user)
    params = {:profile_id => profiles(:occultist).id, :name => 'tester'}
    assert_difference 'Investigator.count', +1 do
      post :create, :investigator => params
      assert_response :found
      assert !assigns(:investigator).blank?
      assert !flash[:notice].blank?
      assert_equal params[:name], assigns(:investigator).name
      assert_equal params[:profile_id], assigns(:investigator).profile_id
      assert_redirected_to edit_web_investigator_path
    end
  end
  
  test 'create failure' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    params = {:profile_id => profiles(:occultist).id}
    assert_no_difference 'Investigator.count' do
      post :create, :investigator => params
      assert_response :found
      assert !assigns(:investigator).blank?
      assert !flash[:investigator].blank?
      assert !flash[:error].blank?
      assert_equal params[:profile_id], flash[:investigator][:profile_id]
      assert_redirected_to new_web_investigator_path
    end
  end  
  
  test 'edit' do
    @controller.login!(@user)
    get :edit
    assert_response :success
    assert_template "web/investigators/edit"
    assert !assigns(:investigator).blank?
    assert !assigns(:equipment).blank?
    assert !assigns(:books).blank?
    assert !assigns(:armaments).blank?
    
    assert @response.body.include?("<legend>#{@investigator.name}</legend>")
    assert @response.body.include?("Level #{assigns(:investigator).level}")
    assert @response.body.include?(assigns(:investigator).profile_name)    
    assert @response.body.include?("<label>Wounds :</label> #{@investigator.wound_status}")
    
    @user.investigator.stats.each do |s|
      assert @response.body.include?("<label>#{s.skill_name} :</label>")
      assert @response.body.include?("<span>#{s.skill_level}</span>")
    end
    [:equipment,:books].each do |k|
      assigns(k).each do |p|
        assert @response.body.include?("<td>#{p.item_name}</td>")
      end
    end
    assigns(:armaments).each do |a|
      assert @response.body.include?("<td>#{a.weapon_name}</td>")
    end    
  end  
  
  test 'edit with skill points' do  
    @user.investigator.update_attribute(:skill_points, 10)
    @controller.login!(@user)
    get :edit
    assert_response :success
    @user.investigator.stats.each do |s|
      assert_tag :tag => "a", :attributes => { :href=>web_stat_path(s.skill_id), 'data-method'=> "put" }
    end
  end
  
  test 'edit with wounds' do
    @investigator.update_attribute(:wounds, 2)
    @investigator.possessions.create(:item_id => @medical.id, :origin => 'gift')
    @controller.login!(@user)
    get :edit
    assert_response :success
    assert_tag :tag => "a", :attributes => { :href => heal_web_investigator_path(@investigator), 'data-method' => "put"}
  end
  
  test 'show' do
    @controller.login!(@user)
    get :show, :id => @investigator.id
    assert_response :success
    assert_template "web/investigators/show"
    assert !assigns(:investigator).blank?
    assert @response.body.include?("<legend>#{assigns(:investigator).name}</legend>")
    assert @response.body.include?(assigns(:investigator).profile_name)
    @user.investigator.stats.each do |s|
      assert @response.body.include?("<label>#{s.skill_name}:</label>")
      assert @response.body.include?("<span>#{s.skill_level}</span>")
    end
  end 
  
  test 'show with wounds' do
    investigator = investigators(:gimel_pi)
    investigator.update_attribute(:wounds, 2)
    @investigator.possessions.create(:item_id => @medical.id, :origin => 'gift')
    @controller.login!(@user)
    get :show, :id => investigator.id
    assert_response :success
    assert_tag :tag => "a", :attributes => { :href => heal_web_investigator_path(:id => investigator.id), 'data-method' => "put"}    
  end  
  
  test 'show as anonymous' do
    get :show, :id => @investigator.id
    assert_response :success
    assert_template "web/investigators/show"
    assert !assigns(:investigator).blank?
  end   
  
  test 'heal for self' do
    @investigator.update_attribute(:wounds, 1)
  
    @controller.login!(@user)
    assert_difference ['@investigator.wounds','@investigator.possessions.items.medical.count'], -1 do
      put :heal
      assert_response :found
      assert !assigns(:investigator).blank?
      assert !assigns(:possession).blank?
      assert !flash[:notice].blank?
      assert_redirected_to edit_web_investigator_path
      @investigator.reload
    end
  end
  
  test 'heal failure' do
    @investigator.update_attribute(:wounds, 1)
    @controller.login!(@user)
    possessions(:aleph_first_aid_kit).destroy
    
    assert_no_difference ['@investigator.wounds'] do
      put :heal
      assert_response :found
      assert !assigns(:investigator).blank?
      assert assigns(:possession).blank?
      assert !flash[:error].blank?
      assert_redirected_to edit_web_investigator_path
      @investigator.reload
    end    
  end  
  
  test 'heal for other investigator' do
    friend = investigators(:gimel_pi)
    friend.update_attribute(:wounds, 2)
    @investigator.update_attribute(:wounds, 1)
    @controller.login!(@user)
    
    assert_difference ['friend.wounds'], -2 do
      assert_difference ['@investigator.wounds','@investigator.possessions.items.medical.count'], -1 do
        put :heal, :id => friend.id
        assert_response :found
        assert !flash[:notice].blank?
        assert !assigns(:investigator).blank?
        assert_redirected_to web_investigator_path(friend)
        @investigator.reload
        friend.reload
      end
    end
  end
  
  test 'require_user' do
    get :edit
    assert_user_required
    
    get :new
    assert_user_required
    
    post :create
    assert_user_required
    
    put :heal
    assert_user_required 
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    get :edit
    assert_investigator_required
    
    put :heal
    assert_investigator_required
  end
  
  test 'require_no_investigator' do
    assert @user.investigator, "investigator required"
    @controller.login!(@user)
    
    get :new
    assert_response :found
    assert_redirected_to edit_web_investigator_path
    assert_equal flash[:error], "You already created an investigator."
    
    post :create
    assert_response :found
    assert_redirected_to edit_web_investigator_path    
    assert_equal flash[:error], "You already created an investigator."
  end    
  
  test 'routes' do
    assert_routing("/web/investigators/new", { :controller => 'web/investigators', :action => 'new' })
    assert_routing("/web/investigators/1", { :controller => 'web/investigators', :action => 'show', :id => '1' })
    assert_routing("/web/investigator/profile", { :controller => 'web/investigators', :action => 'edit' })
    assert_routing({:method => 'put', :path => "/web/investigators/1/heal"}, 
                   {:controller => 'web/investigators', :action => 'heal', :id => '1' })    
    assert_routing({:method => 'put', :path => "/web/investigator/heal"}, 
                   {:controller => 'web/investigators', :action => 'heal' })
    assert_routing({:method => 'post', :path => "/web/investigators"}, 
                   {:controller => 'web/investigators', :action => 'create' })
  end  
end
