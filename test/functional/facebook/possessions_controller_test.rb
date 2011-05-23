require 'test_helper'

class Facebook::PossessionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    init_signed_request
    @item = items(:timepiece)
    @possession = possessions(:aleph_lantern)
    flexmock(@controller).should_receive(:award_daily_income)
    @book = possessions(:aleph_the_zohar)
  end
  
  test 'purchase equipment' do
    @user.investigator.update_attribute(:funds, @item.price)
    
    assert_difference ['Possession.count'], +1 do
      post :purchase, :id => @item.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      assert !flash[:notice].blank?
      assert_redirected_to facebook_items_path
    end
  end 
  
  test 'purchase equipment for js' do
    @user.investigator.update_attribute(:funds, @item.price)
    
    assert_difference ['Possession.count'], +1 do
      post :purchase, :id => @item.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      json = JSON.parse(@response.body)
      assert_equal 'success', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end   
  
  test 'purchase failure' do
    @user.investigator.update_attribute(:funds, @item.price - 1)
    
    assert_no_difference ['Possession.count'] do
      post :purchase, :id => @item.id, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_items_path
    end
  end  
  
  test 'purchase failure for js' do
    @user.investigator.update_attribute(:funds, @item.price - 1)
    
    assert_no_difference ['Possession.count'] do
      post :purchase, :id => @item.id, :signed_request => @signed_request, :format => 'js'
      assert_response :success
      assert !assigns(:item).blank?
      assert !assigns(:possession).blank?
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end  
  
  test 'update book' do
    assert_difference '@book.uses_count', -1 do
      assert_difference '@user.investigator.moxie', +1 do
        put :update, :id => @book.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:possession).blank?
        assert !flash[:notice].blank?
        assert_not_nil assigns(:possession).last_used_at
        assert_redirected_to edit_facebook_investigator_path
        @user.reload
        @book.reload
      end
    end
  end
  
  test 'used_message for book' do
    @controller.instance_variable_set( '@possession', @book )
    expected = 'Studied book and gained +1 moxie for your increased enlightenment.'
    assert_equal expected, @controller.send(:used_message)
  end  
  
  test 'used_title for book' do
    @controller.instance_variable_set( '@possession', @book )
    expected = 'Studied Book'
    assert_equal expected, @controller.send(:used_title)
  end
  
  test 'used_message for artifact' do
    possession = possessions(:aleph_abramelin_oil)
    @controller.instance_variable_set( '@possession', possession )
    expected = "Activated item, which #{possession.item.effect_names}"
    assert_equal expected, @controller.send(:used_message)
  end  

  test 'used_title for artifact' do
    @controller.instance_variable_set( '@possession', possessions(:aleph_abramelin_oil) )
    expected = 'Activated Item'
    assert_equal expected, @controller.send(:used_title)
  end
  
  test 'success_message' do
    @controller.instance_variable_set( '@item', @item )
    expected = "Purchased #{@item.name} for £#{@item.price}"
    assert_equal expected, @controller.send(:success_message)
  end  

  test 'failure_message' do
    @possession.errors[:base] << 'test1'
    @possession.errors[:base] << 'test2'
    @controller.instance_variable_set( '@possession', @possession )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'return_path for purchase' do
    flexmock(@controller).should_receive(:action_name).and_return('purchase')
    assert_equal facebook_items_path, @controller.send(:return_path)
  end  

  test 'return_path for update' do
    flexmock(@controller).should_receive(:action_name).and_return('update')
    assert_equal edit_facebook_investigator_path, @controller.send(:return_path)
  end  
  
  test 'require_user' do
    post :purchase, :id => 1
    assert_user_required
    
    put :update, :id => 1
    assert_user_required    
  end
    
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
  
    post :purchase, :id => 1, :signed_request => @signed_request
    assert_investigator_required
    
    put :update, :id => 1, :signed_request => @signed_request
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing({:method => 'put', :path => "/facebook/possessions/1"}, 
                   {:controller => 'facebook/possessions', :action => 'update', :id => '1' })    
    assert_routing({:method => 'post', :path => "/facebook/possessions/1/purchase"}, 
                   {:controller => 'facebook/possessions', :action => 'purchase', :id => '1' })
  end  
end