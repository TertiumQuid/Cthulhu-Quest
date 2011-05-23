class Touch::InvestigatorsController < Touch::TouchController
  before_filter :require_investigator, :except => [:new,:create]
  # before_filter :require_no_investigator, :only => [:new,:create]
  
  def new
    @investigator = current_user.build_investigator(flash[:investigator])
    @profiles = Profile.order('name ASC').all
  end
  
  def create
    @investigator = current_user.build_investigator(params[:investigator])
    if @investigator.save
      redirect_to edit_touch_investigator_path, :notice => "Your investigator lives and breathes" and return
    else
      flash[:investigator] = params[:investigator]
      flash[:error] = @investigator.errors.full_messages.join(', ')
      redirect_to new_touch_investigator_path and return
    end
  end  
  
private
  def require_no_investigator
    return true if current_user.investigator.blank?
    flash[:error] = "You already created an investigator."
    redirect_to edit_touch_investigator_path and return false
  end  
end