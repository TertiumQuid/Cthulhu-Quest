require 'test_helper'

class FacebookAppRequestTest < ActiveSupport::TestCase
  def setup
    @user = FacebookUserMock.new
    @user.facebook_token = '12345'
    @user.facebook_id = '8790'
  end
  
  test 'send_app_request' do
    params = {:message => 'test', :data => '123'}
    flexmock(@user).should_receive('facebook_access.post').with("/#{@user.facebook_id}/apprequests", params).once.and_return(true)
    
    assert_equal true, @user.send_app_request(params[:message], params[:data])
  end
  
  test 'remove_app_request' do
    flexmock(@user).should_receive('facebook_access.delete').with("/123").once.and_return(true)
    
    assert_equal true, @user.remove_app_request('123')
  end  
end