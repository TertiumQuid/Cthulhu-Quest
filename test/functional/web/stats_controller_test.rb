require 'test_helper'

class Web::StatsControllerTest < ActionController::TestCase
  def setup
    @stat = stats(:aleph_research)
    @user = users(:aleph)
  end
  
  test 'update' do
    @user.investigator.update_attribute(:skill_points, 1)
    @controller.login!(@user)
    
    assert_difference '@user.reload.investigator.skill_points', -1 do
      assert_difference '@stat.skill_points', +1 do      
        put :update, :id => @stat.skill_id
        assert_response :found
        assert !assigns(:stat).blank?
        @stat.reload
        expected = "Added +1 skill point to #{@stat.skill_name} and advanced one step on the road to mastery. #{@stat.next_level_skill_points - @stat.skill_points} points more until advancement."
        assert_equal expected, flash[:notice]
        assert flash[:error].blank?
        assert_redirected_to edit_web_investigator_path
      end
    end
  end
  
  test 'update and advance_level!' do  
    @user.investigator.update_attribute(:skill_points, 1)
    @stat.update_attribute(:skill_points, @stat.next_level_skill_points - 1)
    @controller.login!(@user)
    assert_difference '@stat.skill_level', +1 do      
      put :update, :id => @stat.skill_id
      @stat.reload
      expected = "Added +1 skill point to #{@stat.skill_name} and advanced to level #{@stat.skill_level}. Pour yourself a drink!"
      assert_equal expected, flash[:notice]
    end
  end
  
  test 'require_user' do
    put :update, :id => 1
    assert_user_required
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    put :update, :id => 1
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/web/stats/1"}, 
                   {:controller => 'web/stats', :action => 'update', :id => '1' })
  end  
end