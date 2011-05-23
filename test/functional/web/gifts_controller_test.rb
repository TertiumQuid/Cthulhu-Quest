require 'test_helper'

class Web::GiftsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @recipient = investigators(:beth_pi)
  end
  
  test 'gift funds' do
    @controller.login!(@user)
    assert_difference '@investigator.reload.funds', -1 do
      assert_difference '@recipient.reload.funds', +1 do
        post :create, :investigator_id => @recipient.id, :gift => {:gifting => '1'}
        assert_response :found
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        assert !flash[:notice].blank?
        assert_redirected_to web_investigator_path(@recipient)
      end
    end
  end
  
  test 'gift with insufficient funds' do
    @investigator.update_attributes!(:funds => 0, :last_income_at => Time.now)
    @controller.login!(@user)
    
    assert_no_difference '@investigator.reload.funds' do
      assert_no_difference '@recipient.reload.funds' do
        post :create, :investigator_id => @recipient.id, :gift => {:gifting => '1'}
        assert_response :found
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        assert !flash[:error].blank?
        assert_redirected_to web_investigator_path(@recipient)
      end
    end
  end
  
  test 'gift item' do
    @controller.login!(@user)
    possession = possessions(:aleph_lantern)
    assert_difference '@investigator.reload.possessions.count', -1 do
      assert_difference '@recipient.reload.possessions.count', +1 do
        post :create, :investigator_id => @recipient.id, :gift => {:gifting => possession.item_name.downcase}
        assert_response :found
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        assert !flash[:notice].blank?
        assert_redirected_to web_investigator_path(@recipient)
      end
    end
  end
  
  test 'gift missing item' do
    @controller.login!(@user)
    assert_no_difference '@investigator.reload.possessions.count' do
      assert_no_difference '@recipient.reload.possessions.count' do
        post :create, :investigator_id => @recipient.id, :gift => 'Cigarettes'
        assert_response :found
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        assert !flash[:error].blank?
        assert_redirected_to web_investigator_path(@recipient)
      end
    end
  end
  
  test 'require_user' do
    post :create, :investigator_id => 1
    assert_user_required
  end  
  
  test 'require_investigator' do
    assert @user.investigator.destroy
    @controller.login!(@user)
    
    post :create, :investigator_id => 1
    assert_investigator_required
  end
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/web/investigators/1/gift"}, 
                   {:controller => 'web/gifts', :action => 'create', :investigator_id => '1' })
  end
end