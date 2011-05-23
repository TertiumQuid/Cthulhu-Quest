module ActionController
  module UxSupport
    JSON_RESPONSE_KEYS = [:success,:failure,:redirect,:unauthorized,:session]
    
    def json_response_hash
      { 
        :status => nil, 
        :html => nil,  
        :json => nil,
        :title => nil,
        :message => nil, 
        :to => nil
      }.with_indifferent_access
    end

    def fb_url(path,force=false)
      Rails.env.production? || force ? "http://apps.facebook.com/cthulhuquest#{path.gsub('/facebook','')}" : path
    end
        
    def render_json_response(type, hash)
      opts = { :json => json_response_hash.merge( :status => type ).merge( hash ) }
      render(opts)
    end

    def render_and_respond(type, hash={})
      hash = hash.with_indifferent_access
      respond_to do |format|
        format.js do 
          if hash.blank?
            render_to_string :layout => false, :content_type => 'text/html'
          else
            render_json_response(type, hash)
          end
        end
        format.html do
          flash[:error] = hash[:message] if [:error,:failure,:session].include?(type)
          flash[:notice] = hash[:message]

          if hash[:to]
            redirect_to hash[:to] and return false
          else
            render
          end
        end
      end    
    end   
     
  end
end