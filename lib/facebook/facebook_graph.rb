require 'oauth2'
require File.expand_path('../facebook_app_request', __FILE__)

module Facebook
  module Graph
    include Facebook::AppRequest
    
    def facebook_user_id
      respond_to?(:facebook_id) ? facebook_id : nil
    end
    
    def facebook_access_token
      respond_to?(:facebook_token) ? facebook_token : nil
    end
    
    def facebook_client
      return @facebook_client if defined?(@facebook_client)
      @facebook_client = OAuth2::Client.new( 
         AppConfig.facebook.app_id, 
         AppConfig.facebook.app_secret, 
         :site => AppConfig.facebook.site 
      )
    end
    
    def facebook_access
      return @facebook_access if defined?(@facebook_access)
      @facebook_access = OAuth2::AccessToken.new( 
         facebook_client, 
         facebook_access_token
      )
    end
  end
end