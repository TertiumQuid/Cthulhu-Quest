require 'test_helper'

class FacebookGraphTest < ActiveSupport::TestCase
  def setup
    @grapher = FacebookGraphMock.new
    @user = FacebookUserMock.new
    @user.facebook_token = '12345'
    @user.facebook_id = '8790'
  end
  
  test 'facebook_access_token with facebook_token' do
    assert_nil @grapher.facebook_access_token
    assert_equal @user.facebook_token, @user.facebook_access_token
  end
  
  test 'facebook_user_id with facebook_id' do
    assert_nil @grapher.facebook_access_token
    assert_equal @user.facebook_id, @user.facebook_user_id
  end  
  
  test 'facebook_client' do
    client = @grapher.facebook_client
    assert client.is_a?(OAuth2::Client)
    assert_equal AppConfig.facebook.app_id, client.id
    assert_equal AppConfig.facebook.app_secret, client.secret
    assert_equal AppConfig.facebook.site, client.site
  end  
  
  test 'facebook_access' do
    assert_nil @user.instance_variable_get('@facebook_client')
    access = @user.facebook_access
    assert access.is_a?(OAuth2::AccessToken)
    assert_not_nil @user.instance_variable_get('@facebook_client')
    assert_equal @user.facebook_token, access.token
  end  
end