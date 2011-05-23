class AuthorizationController < ApplicationController
  respond_to :html
  
  def authorize
    redirect_to facebook_client.web_server.authorize_url(
      :redirect_uri => redirect_uri,
      :scope => 'email,offline_access',
      :display => (display == 'web' ? 'page' : display)
    )    
  end
  
  def deauthorize
    Rails.logger.info "DEAUTHORIZED: #{params.inspect}"
    render :nothing => true
  end
  
  def callback
    if code = params[:code]
      access = facebook_client.web_server.get_access_token(code, :redirect_uri => redirect_uri)
      user = User.find_or_create_from_access( access )
      login!(user)
    end

    notice = if user.blank?
      (params[:error] == "access_denied") ? "Shan't you play? Ok, nevermind then. Maybe later?" : "User doesn't exist"
    elsif user.investigator_id.blank?
      "Welcome to Cthulhu Quest, your existence was confirmed. Create your investigator now to start playing."
    else
      "Welcome back to Cthulhu Quest, your existence was confirmed; and now, the story continues..."
    end
    url = user.blank? ? facebook_root_path : callback_redirect_url_for(user)
    redirect_to url, :notice => notice and return
  end
  
private
  def platform
    if !params[:platform].blank?
      params[:platform]
    elsif (params[:controller] ||= '').include?("facebook")
      'facebook'
    elsif (params[:controller] ||= '').include?("touch")
      'touch'
    else
      'web'
    end
  end
  
  def callback_root(goto)
    (goto == 'facebook') ? 'http://apps.facebook.com/cthulhuquest' : "/#{goto}"
  end
  
  def callback_redirect_url_for(user)
    goto = params[:platform].blank? ? display : params[:platform]
      
    if user.blank? || user.investigator_id.blank?
      return "#{callback_root(goto)}/investigators/new"
    else
      return "#{callback_root(goto)}/investigator/profile"
    end
  end
  
  def redirect_uri
    uri = URI.parse("http://#{AppConfig.domain}")
    uri.path = '/oauth/callback'
    uri.query = "platform=" + platform
    uri.to_s
  end
end