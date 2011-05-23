require 'base64'

class Facebook::FacebookController < ApplicationController
  layout 'facebook'
  respond_to :html, :js
  
  before_filter :require_signed_request

  helper_method :authorized_facebook?, :authorized_app?
  
  def home
    render_and_respond :success
  end
  
  def authorized_facebook?
    !params[:facebook].blank?
  end
  
  def authorized_app?
    authorized_facebook? && !params[:facebook][:oauth_token].blank?
  end
  
private

  def require_signed_request
    return unless signed_request = params[:signed_request]
    
    encoded_sig, payload = signed_request.split('.')
    sig = str_to_hex(base64_url_decode(encoded_sig))
    
    if facebook_signed?( sig, payload )
      data = ActiveSupport::JSON.decode base64_url_decode(payload)
      params[:facebook] = data.with_indifferent_access if data.is_a?(Hash)
      Rails.logger.info "Facebook Params #{data.inspect}"
    else
      params[:facebook] = nil
    end
  end

  def base64_url_decode(str)
    str += '=' * (4 - str.length.modulo(4))
    Base64.decode64(str.gsub("-", "+").gsub("_", "/"))
  end
  
  def str_to_hex(str)
    (0..(str.size-1)).to_a.map do |i|
      number = str[i].to_s(16)
      (str[i] < 16) ? ('0' + number) : number
    end.join
  end
  
  def facebook_sig(payload)
    OpenSSL::HMAC.hexdigest('sha256', AppConfig.facebook.app_secret, payload)
  end
    
  def facebook_signed?(sig, payload)
    sig == facebook_sig(payload)
  end
end