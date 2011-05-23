# honor Facebook Canvas App POST requirement while preserving RESTful GET routing

module Rack
  class FacebookPosts
    
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      
      if request.post? && request.params['signed_request']
        env["REQUEST_METHOD"] = 'GET'
      end
      
      return @app.call(env)
    end
  
  end
end