class Facebook::AlliesController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def index
    @allies = current_investigator.allies.ally 
    @friends = current_user.unallied_friends.investigator
    @socials = current_investigator.available_socials.inviting( current_investigator.id )
    
    render_and_respond :success
  end
  
  def create
    @ally = current_investigator.allies.new( params[:ally] )
    if @ally.save
      render_and_respond :success, :message => success_message, :title => "Added ally", :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => "Couldn't remove ally", :to => return_path
    end
  end
  
  def destroy
    @ally = current_investigator.allies.find( params[:id] )
    @ally.destroy
    
    render_and_respond :success, :message => "Ally removed from your Inner Circle.", :title => 'Removed ally', :to => return_path
  end
  
private

  def return_path
    fb_url( facebook_allies_path )
  end  
  
  def failure_message
    @ally.errors.full_messages.join(', ')
  end

  def success_message
    "You inducted the worthy #{@ally.name} to your Inner Circle. You'll now be able to request their investigative skills with plot intrigues."
  end  
end