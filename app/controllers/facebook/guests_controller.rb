class Facebook::GuestsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def new
    @social = current_investigator.available_socials.find_by_id( params[:social_id] )
    @guest = current_investigator.guests.new(:social => @social)
    
    render_and_respond :success, :html => new_html, :title => "Attend #{@social.social_function.name}"
  end
    
  def create
    @social = current_investigator.available_socials.find_by_id( params[:social_id] )
    @guest = current_investigator.guests.build( :social => @social, :status => params[:status] )
    
    if @guest.save
      render_and_respond :success, :message => success_message, :title => 'Sent RSVP', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not RSVP', :to => return_path
    end
  end

private

  def return_path
    facebook_social_functions_path
  end  

  def failure_message
    @guest.errors.full_messages.join(', ')
  end

  def success_message
    "You've pledged your attendance at the #{@social.social_function.name} where you will #{@guest.description}"
  end
  
  def new_html
    render_to_string(:layout => false, :template => "facebook/guests/new.html")
  end  
end