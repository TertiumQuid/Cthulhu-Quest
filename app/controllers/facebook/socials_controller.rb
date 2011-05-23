class Facebook::SocialsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @social_function = SocialFunction.find( params[:social_function_id] )
    @social = current_investigator.socials.new(:social_function => @social_function)
    
    if @social.save
      render_and_respond :success, :message => success_message, :title => 'Hosting social function', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not host social', :to => return_path
    end  
  end
  
  def update
    @social_function = SocialFunction.find( params[:social_function_id] )
    @social = current_investigator.socials.scheduled.active.find( params[:id] )
    
    if @social.host!
      render_and_respond :success, :message => reward_message, :title => 'Hosted social function', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not host social', :to => return_path
    end    
  end

private

  def return_path
    facebook_social_functions_path
  end  

  def failure_message
    @social.errors.full_messages.join(', ')
  end

  def success_message
    "You are now preparing for the #{@social_function.name}. In #{SocialFunction::TIMEFRAME} hours, your social function will be scheduled and can be hosted. Until that time, your allies may attend as guests, sharing in the event's comradarie."
  end  

  def reward_message
    ([ "You concluded this social function, with the following results:\n", @social.logs[:host_reward] ] + @social.logs[:guest_rewards]).join("\n")
  end
end