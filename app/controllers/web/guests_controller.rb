class Web::GuestsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @social = Social.active.for_allies( ally_ids ).find( params[:social_id] )
    @guest = current_investigator.guests.build(:social => @social, :status => params[:status])
    if @guest.save
      flash[:notice] = "You've pledged your attendance at the #{@social.social_function.name} where you will #{@guest.description}"
    else
      flash[:error] = @guest.errors.full_messages.join(', ')
    end      
    redirect_to web_social_functions_path and return
  end
  
private

  def ally_ids
    current_investigator.inner_circle.map(&:id)
  end  
end