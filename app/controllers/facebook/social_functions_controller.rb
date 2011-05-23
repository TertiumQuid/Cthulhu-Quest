class Facebook::SocialFunctionsController < Facebook::FacebookController
  def index
    @social_functions = SocialFunction.all
    if current_investigator
      @social = current_investigator.socials.guests.active.first 
      @socials = current_investigator.available_socials.inviting( current_investigator.id )
    end
    render_and_respond :success
  end
end