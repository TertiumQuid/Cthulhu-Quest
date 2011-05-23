class Web::AlliesController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def index
    @allies = current_investigator.allies.investigator
    @contacts = current_investigator.contacts.includes({:character => :user})
    @friends = current_user.friends
    @friends = @friends.investigating unless @friends.blank?
    
    @introductions = current_investigator.introductions.arranged
  end
  
  def create
    @ally = current_investigator.allies.create!( params[:ally] )
    unless @ally.new_record?
      flash[:notice] = "You inducted the worthy #{@ally.name} to your Inner Circle. "
      flash[:notice] = flash[:notice] + "You'll now be able to request their investigative skills with plot intrigues."
    else
      flash[:error] = @ally.errors.full_messages.join(', ')
    end
    redirect_to web_allies_path and return
  end
  
  def destroy
    @ally = current_investigator.allies.find(params[:id])
    @ally.destroy
    redirect_to web_allies_path, :notice => "Ally removed from your Inner Circle."
  end
end