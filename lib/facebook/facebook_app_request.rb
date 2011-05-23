module Facebook
  module AppRequest
    def send_app_request(message,data=nil)
      response = facebook_access.post "/#{facebook_user_id}/apprequests", 
                                      {:message => message, :data => data}                         
    end
    
    def remove_app_request(id)
      response = facebook_access.delete "/#{id}"
    end
  end
end