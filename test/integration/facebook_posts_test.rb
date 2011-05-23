require 'test_helper'

class FacebookPostsTest < ActionController::IntegrationTest
  def setup
    set_signed_request_instance
  end
  
  test 'POST with signed_request' do
    post '/facebook/investigators/new', :signed_request => @signed_request
    assert_response :success
  end
  
  test 'POST without signed_request' do
    assert_raises ActionController::RoutingError do
      post '/facebook/investigators/new'
    end
  end
end