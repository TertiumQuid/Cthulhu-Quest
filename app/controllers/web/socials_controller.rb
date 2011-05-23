class Web::SocialsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @social_function = SocialFunction.find(params[:social_function_id])
    @social = current_investigator.socials.new(:social_function => @social_function)
    
    if @social.save
      notice = "You are now preparing for the #{@social_function.name}. "
      notice = notice + "In #{SocialFunction::TIMEFRAME} hours, your social function will be scheduled and can be hosted. "
      notice = notice + "Until that time, your allies may attend as guests, sharing in the event's comradarie."
      flash[:notice] = notice
    else
      flash[:error] = @social.errors.full_messages.join(', ')
    end  
    
    redirect_to web_social_functions_path and return
  end
  
  def update
    @social = current_investigator.socials.find(params[:id])
    
    if @social.host!
    else
      flash[:error] = @social.errors.full_messages.join(', ')
    end  
    
    redirect_to web_social_functions_path and return
  end
end