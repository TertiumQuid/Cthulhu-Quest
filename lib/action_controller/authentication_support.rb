module ActionController
  module AuthenticationSupport
    def session_id
      return request.session_options[:id]
    end
    
    def user_id
      session[:user_id]
    end

    def current_session
      return @current_session unless @current_session.blank?
      @current_session = Session.find_or_initialize_by_session_id(session_id)
    end
    
    def current_user
      return @current_user unless @current_user.blank?
        
      if Rails.env.development? # Todo: remove, DEV HACK!
        @current_user = User.first
      elsif !user_id.blank?
        @current_user = User.find_by_id( user_id )
      elsif !cookies[:_cthulhu_quest_nonce].blank?
        @current_user = User.find_by_nonce( cookies[:_cthulhu_quest_nonce] )
      elsif params[:facebook] && params[:facebook][:user_id]
        @current_user = User.find_by_facebook_id( params[:facebook][:user_id] )
      end
      
      login!( @current_user ) if @current_user && session[:user_id].blank? # login unless already logged in by session
      if @current_user
        @current_user.set_last_login_at(:save => true) 
        recover_daily_wounds
        award_daily_income
        update_from_facebook
      end
      @current_user
    end
    
    def logged_in?
      !current_user.blank?
    end
    
    def login!(user_or_id)
      return if user_or_id.blank?
      
      user_or_id = User.find_by_id( user_or_id ) unless user_or_id.is_a?(User)
      session[:user_id] = user_or_id.id
      user_or_id.set_nonce!(:save => true)
      current_session.update_attribute(:user_id, session[:user_id])
      store_login_cookie
    end

    def require_user
      return true unless current_user.blank?
      render_and_respond :session, :to => root_display_path, :message => "You must be logged in to go there."
    end    
    
    def store_login_cookie
      if current_user && current_user.nonce
        cookies[:_cthulhu_quest_nonce] = {:value => current_user.nonce, :expires => 3.months.from_now} 
      end
    end
    
    def delete_login_cookie
      cookies.delete :_cthulhu_quest_nonce
    end
  end
end