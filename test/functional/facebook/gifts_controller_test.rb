require 'test_helper'

class Facebook::GiftsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @sender = investigators(:aleph_pi)
    @investigator = investigators(:beth_pi)
    @gift = @sender.giftings.new(:investigator => @investigator, :gifting => 1)
    
    @possession = possessions(:aleph_lantern)
    @armament = armaments(:aleph_colt_45_automatic)
    
    flexmock(@controller).should_receive(:award_daily_income)
    init_signed_request
  end
  
  test 'create' do
    assert_difference '@sender.reload.funds', -1 do
      assert_difference '@investigator.reload.funds', +1 do
        post :create, :investigator_id => @investigator.id, :gift => {:gifting => '1'}, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        assert !flash[:notice].blank?
        assert_redirected_to facebook_investigator_path(@investigator)
      end
    end
  end
  
  test 'create for js' do
    @controller.login!(@user)
    assert_difference '@sender.reload.funds', -1 do
      assert_difference '@investigator.reload.funds', +1 do
        post :create, :investigator_id => @investigator.id, :gift => {:gifting => '1'}, :format => 'js'
        assert_response :success
        assert !assigns(:investigator).blank?
        assert !assigns(:gift).blank?
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['title'].blank?
        assert !json['message'].blank?
      end
    end
  end
  
  test 'create failure' do
    @sender.update_attribute(:funds, 0)
    assert_no_difference ['@sender.reload.funds','@investigator.reload.funds'] do
      post :create, :investigator_id => @investigator.id, :gift => {:gifting => '1'}, :signed_request => @signed_request
      assert_response :found
      assert !assigns(:investigator).blank?
      assert !assigns(:gift).blank?
      assert !flash[:error].blank?
      assert_redirected_to facebook_investigator_path(@investigator)
    end
  end  
  
  test 'create failure for js' do
    @sender.update_attribute(:funds, 0)
    assert_no_difference ['@sender.reload.funds','@investigator.reload.funds'] do
      post :create, :investigator_id => @investigator.id, :gift => {:gifting => '1'}, :format => 'js', :signed_request => @signed_request
      assert_response :success
      assert !assigns(:investigator).blank?
      assert !assigns(:gift).blank?
      json = JSON.parse(@response.body)
      assert_equal 'failure', json['status']
      assert !json['title'].blank?
      assert !json['message'].blank?
    end
  end  
  
  test 'failure_message' do
    @gift.errors[:base] << 'test1'
    @gift.errors[:base] << 'test2'
    @controller.instance_variable_set( '@gift', @gift )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end
  
  test 'success_message with funds' do
    @controller.instance_variable_set( '@gift', @gift )
    expected = "You sent your ally a gift of £1, and they shall be pleased to receive it."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'success_message with item' do
    gift = @sender.giftings.new(:investigator => @investigator, :gifting => @possession.item_name)
    @controller.instance_variable_set( '@gift', gift )
    expected = "You sent your ally your #{@possession.item_name} as a gift. They shall be pleased to receive it."
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'success_message with weapon' do
    gift = @sender.giftings.new(:investigator => @investigator, :gifting => @armament.weapon_name)
    @controller.instance_variable_set( '@gift', gift )
    expected = "You sent your ally your #{@armament.weapon_name} as a gift. They shall be pleased to receive it."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'return_path' do
    @controller.instance_variable_set( '@investigator', @investigator )
    assert_equal facebook_investigator_path(@investigator), @controller.send(:return_path)
  end
  
  test 'require_user' do
    post :create, :investigator_id => '1'
    assert_user_required
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    post :create, :investigator_id => '1', :signed_request => @signed_request
    assert_investigator_required
  end    
  
  test 'routes' do
    assert_routing({:method => 'post', :path => "/facebook/investigators/1/gift"}, 
                   {:controller => 'facebook/gifts', :action => 'create', :investigator_id => '1' })
  end  
end