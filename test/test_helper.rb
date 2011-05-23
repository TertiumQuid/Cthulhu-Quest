ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'flexmock/test_unit'

class ActiveSupport::TestCase
  fixtures :all
  
  require 'test_helper'

  class FacebookGraphMock
    include Facebook::Graph
  end

  class FacebookUserMock
    include Facebook::Graph
    attr_accessor :facebook_token, :facebook_id   
  end
    
  def init_signed_request(user=nil)
    @user = user || users(:aleph)
    @user.update_attribute(:facebook_id, '608302347')
    set_signed_request_instance
    @controller.params[:signed_request] = @signed_request if @controller
  end
  
  def set_signed_request_instance
    @signed_request = 'jCjt-B3AwUNpaHkHBCrV4nRfIXcGKQXjg5eiClEW0pA.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImV4cGlyZXMiOjAsImlzc3VlZF9hdCI6MTI5MTU2MTY3OCwib2F1dGhfdG9rZW4iOiIxNTUzNDU0MjExNTQ1MTR8YTQ1MzU1YjUwNWI0NGY1ZjBiMjA4MTkyLTYwODMwMjM0N3xuREtZS0lBUjVjcGJoSmNCMHJTXzdDS1ljWlUiLCJ1c2VyX2lkIjoiNjA4MzAyMzQ3In0'
  end
  
  def assert_user_required
    assert_response :found
    assert_redirected_to @controller.send(:root_display_path)
    assert_equal flash[:error], "You must be logged in to go there."
  end
  
  def assert_investigator_required
    assert_response :found
    assert_redirected_to @controller.send(:root_display_path)
    assert_equal flash[:error], "You must control an investigator to go there."    
  end
  
  def assert_html_response
    assert_equal "text/html", @response.content_type
  end
  
  def assert_js_response
    assert_equal "text/javascript", @response.content_type
  end
end

### network overides ###

module OAuth2
  class AccessToken
    # mock ALL facebook get requests during tests, and return any necessary mock data
    def get(path, params = {}, headers = {})
      {:friends => {:data => [{:id => '100001627764205'},{:id => '100001591165226'}]}}.to_json
    end
  end  
end