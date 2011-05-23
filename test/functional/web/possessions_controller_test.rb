require 'test_helper'

class Web::PossessionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @possession = possessions(:aleph_lantern)
    @item = items(:timepiece)
    flexmock(@controller).should_receive(:award_daily_income)
  end

  test 'purchase equipment' do
    @user.investigator.update_attribute(:funds, @item.price)
    @controller.login!(@user)
    
    assert_difference ['Possession.count'], +1 do
      post :purchase, :id => @item.id
      assert_response :found
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      assert !flash[:notice].blank?
      assert_redirected_to web_items_path
    end
  end
  
  test 'purchase artifact' do
    @item = items(:abramelin_oil)
    @user.investigator.update_attribute(:funds, @item.price)
    @controller.login!(@user)
    
    assert_difference ['Possession.count'], +1 do
      post :purchase, :id => @item.id
      assert_response :found
      assert !assigns(:item).blank?
    end
  end  
  
  test 'purchase failure' do
    @user.investigator.update_attribute(:funds, @item.price - 1)
    @controller.login!(@user)
    
    assert_no_difference ['Possession.count'] do
      post :purchase, :id => @item.id
      assert_response :found
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      assert !flash[:error].blank?
      assert_redirected_to web_items_path
    end
  end  
      
  test 'destroy' do
    @controller.login!(@user)
    assert_difference ['Possession.count'], -1 do
      delete :destroy, :id =>  @possession.id
      assert_response :found
      assert !flash[:notice].blank?
      assert_redirected_to edit_web_investigator_path
    end    
  end
  
  test 'require_user' do
    post :purchase, :id => 1
    assert_user_required
    
    delete :destroy, :id => 1
    assert_user_required 
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    post :purchase, :id => 1
    assert_investigator_required
    
    delete :destroy, :id => 1
    assert_investigator_required
  end  
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/web/possessions/1/purchase"}, 
                   {:controller => 'web/possessions', :action => 'purchase', :id => '1' })
    assert_routing({:method => 'delete', :path => "/web/possessions/1"}, 
                   {:controller => 'web/possessions', :action => 'destroy', :id => '1' })
  end  
end