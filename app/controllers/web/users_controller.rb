class Web::UsersController < Web::WebController
  before_filter :require_user
  
  def show
    @user = current_user
  end
  
  def logout
    session[:user_id] = nil
    flash[:notice] = "You logged out."
    redirect_to root_path and return
  end
end