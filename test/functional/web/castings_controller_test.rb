require 'test_helper'

class Web::CastingsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @spell = spells(:sway_of_the_adept)
  end
  
  test 'create' do
    @controller.login!(@user)
    assert_difference ['Casting.count','@investigator.castings.count'], +1 do      
      post :create, :spell_id => @spell.id
      assert_response :found
      assert !assigns(:spell).blank?
      assert !assigns(:casting).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_spellbooks_path
    end
  end
  
  test 'create failure' do
    @investigator.castings.create(:spell => @spell)
    @controller.login!(@user)
    
    assert_no_difference ['Casting.count','@investigator.castings.count'], +1 do      
      post :create, :spell_id => @spell.id
      assert_response :found
      assert !assigns(:spell).blank?
      assert !assigns(:casting).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_spellbooks_path
    end
  end
  
  test 'require_user' do
    post :create, :spell_id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    post :create, :spell_id => 1
    assert_investigator_required
  end  
  
  test 'routes' do  
    assert_routing({:method => 'post', :path => "/web/spells/1/castings"}, 
                  {:controller => 'web/castings', :action => 'create', :spell_id => '1' })
  end  
end