require 'oauth2'
require 'json'

class ApplicationController < ActionController::Base
  include ActionController::AuthenticationSupport
  include ActionController::UxSupport
  
  protect_from_forgery
  helper_method :facebook_client, :display, :logged_in?, :current_user, :current_investigator
  
  rescue_from ActionController::InvalidAuthenticityToken, :with => :rescue_bad_token
  
  def landing
    redirect_to_root
  end

  def display
    if request.env['HTTP_USER_AGENT'] && (
         request.env['HTTP_USER_AGENT'].include?('iPhone') ||
         request.env['HTTP_USER_AGENT'].include?('Android')
       )
      'touch'
    elsif !params[:signed_request].blank? || request.url.include?('facebook/')
      'facebook'
    else
      'web'
    end
  end

  def root_display_path
    case display
      when 'touch' 
        touch_root_path
      when 'web' 
        web_root_path
      when 'facebook' 
        fb_url( facebook_root_path )
    end    
  end

  def rescue_bad_token
    render_and_respond :session, :title => "Session Timeout", :to => root_display_path
  end
      
protected

  def redirect_to_root
    redirect_to root_display_path and return false
  end
  
  def current_investigator
    return @current_investigator if defined?(@current_investigator)
    return (@current_investigator = User.first.investigator) if Rails.env.development? # Todo: remove, DEV HACK!
    
    
    @current_investigator = (current_user && current_user.investigator) ? current_user.investigator : nil
  end

  def facebook_client
    return @facebook_client if defined?(@facebook_client)
    @facebook_client = OAuth2::Client.new( 
       AppConfig.facebook.app_id, 
       AppConfig.facebook.app_secret, 
       :site => AppConfig.facebook.site 
    )
  end  
  
  def require_investigator
    return true unless current_user && current_user.investigator.blank?
    flash[:error] = "You must control an investigator to go there."
    redirect_to_root
  end
  
  def recover_daily_wounds
    # cheating by using last income at timestamp as wound recovery flag
    return unless needs_daily_update?
    current_investigator.recover_wounds!
  end
  
  def award_daily_income
    return unless needs_daily_update?
    
    current_investigator.earn_income!
    flash[:notice] ||= "You earned £#{current_investigator.income} for logging in today."
  end
  
  def update_from_facebook
    return unless current_user && 
                  (current_user.last_facebook_update_at.blank? || 
                  current_user.last_facebook_update_at < (Time.now - 8.hours) )
                  
    access = OAuth2::AccessToken.new( facebook_client, current_user.facebook_token )
    current_user.update_facebook_friends_from_access(access)
  end
  
  def needs_daily_update?
    !current_investigator.blank? && (current_investigator.last_income_at.nil? || current_investigator.last_income_at < (Time.now - 1.day) )
  end  
end
