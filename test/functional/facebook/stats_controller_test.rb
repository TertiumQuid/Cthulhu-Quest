require 'test_helper'

class Facebook::StatsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @stat = stats(:aleph_research)
    init_signed_request
  end
  
  test 'update' do
    @user.investigator.update_attribute(:skill_points, 1)
    
    assert_difference '@user.reload.investigator.skill_points', -1 do
      assert_difference '@stat.skill_points', +1 do      
        put :update, :id => @stat.skill_id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:stat).blank?
        assert !assigns(:original_skill_level).blank?
        assert !flash[:notice].blank?
        @stat.reload
        assert_redirected_to edit_facebook_investigator_path
      end
    end
  end 
  
  test 'update failure' do
    @user.investigator.update_attribute(:skill_points, 0)
    
    assert_no_difference ['@user.reload.investigator.skill_points','@stat.skill_points'] do
      put :update, :id => @stat.skill_id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:stat).blank?
      assert !assigns(:original_skill_level).blank?
      assert !flash[:error].blank?
      @stat.reload
      assert_redirected_to edit_facebook_investigator_path
    end
  end   
  
  test 'update for js' do
    @user.investigator.update_attribute(:skill_points, 1)
    
    assert_difference '@user.reload.investigator.skill_points', -1 do
      assert_difference '@stat.skill_points', +1 do      
        put :update, :id => @stat.skill_id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        assert !assigns(:stat).blank?
        assert !assigns(:original_skill_level).blank?
        json = JSON.parse(@response.body)
        assert_js_response
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
        @stat.reload
      end
    end
  end  
  
  test 'return_path' do
    assert_equal edit_facebook_investigator_path, @controller.send(:return_path)
  end  
  
  test 'failure_message' do
    @stat.errors[:base] << 'test1'
    @stat.errors[:base] << 'test2'
    @controller.instance_variable_set( '@stat', @stat )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end

  test 'success_message' do
    @controller.instance_variable_set( '@stat', @stat )
    @controller.instance_variable_set( '@original_skill_level', @stat.skill_level )
    expected = "Added +1 skill point to #{@stat.skill_name} and advanced one step on the road to mastery. #{(@stat.next_level_skill_points - @stat.skill_points)} " + (@stat.next_level_skill_points - @stat.skill_points > 1 ? 'points' : 'point') + " more until advancement."
    assert_equal expected, @controller.send(:success_message)    
  end
  
  test 'success_message with level advance' do
    @controller.instance_variable_set( '@stat', @stat )
    @controller.instance_variable_set( '@original_skill_level', @stat.skill_level - 1 )
    expected = "Added +1 skill point to #{@stat.skill_name} and advanced to level #{@stat.skill_level}. Pour yourself a drink!"
    assert_equal expected, @controller.send(:success_message)    
  end
  
  test 'advanced_skill?' do
    @controller.instance_variable_set( '@stat', @stat )
    @controller.instance_variable_set( '@original_skill_level', @stat.skill_level + 1 )
    assert_equal false, @controller.send(:advanced_skill?)
    
    @controller.instance_variable_set( '@original_skill_level', @stat.skill_level )
    assert_equal false, @controller.send(:advanced_skill?)
    
    @controller.instance_variable_set( '@original_skill_level', @stat.skill_level - 1 )
    assert_equal true, @controller.send(:advanced_skill?)    
  end
    
  test 'require_user' do
    put :update, :id => 1
    assert_user_required
  end  

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required   
  end
    
  test 'routes' do
    assert_routing({:method => 'put', :path => "/facebook/stats/1"}, 
                  {:controller => 'facebook/stats', :action => 'update', :id => '1' })
  end  
end