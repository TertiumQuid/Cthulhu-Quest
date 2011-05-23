class Facebook::InvestigatorsController < Facebook::FacebookController
  before_filter :require_user, :only => [:edit,:destroy]  
  before_filter :require_investigator, :only => [:edit,:destroy]
  before_filter :require_no_investigator, :only => [:new,:create]
  before_filter :require_authorized_login, :only => [:create]
  
  def show
    @investigator = Investigator.find(params[:id])
    @psychoses = @investigator.psychoses
    if current_investigator
      @ally = current_investigator.allies.find_by_ally_id(params[:id]) 
      @medical = current_investigator.possessions.items.medical.exists? if @investigator.wounded?
      @spirits = current_investigator.possessions.items.spirit.exists? if @investigator.maddened?
      @assignments = current_investigator.assignments.investigation.where(:ally_id => params[:id])
      @gift = current_investigator.giftings.new
    end
    render_and_respond :success, :html => show_html, :title => "Investigator: #{@investigator.name}"
  end
  
  def new
    @investigator = Investigator.new
    @profiles = Profile.order('name ASC').all
    render_and_respond :success
  end
  
  def create
    @investigator = current_user.build_investigator( investigator_params )
    
    if @investigator.save
      render_and_respond :redirect, :message => success_message, :title => 'Investigator Joined', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not Continue', :to => return_path
    end
  end
  
  def edit
    @investigator = current_investigator
    @equipment = @investigator.possessions.items.inventory
    @medical = @equipment.select{|m| m.item.medical? }
    @books = @investigator.library
    @armaments = @investigator.armaments.weapons
    @stats = @investigator.all_stats
    @psychoses = @investigator.psychoses.insanity
    
    render_and_respond :success
  end
  
  def destroy
    current_investigator.retire!
    
    render_and_respond :redirect, :message => retired_message, :title => "Retired Investigator", :to => new_facebook_investigator_path
  end
  
private
  def return_path
    if @investigator.new_record?
      fb_url( new_facebook_investigator_path )
    else
      fb_url( edit_facebook_investigator_path )
    end
  end
  
  def failure_message
    @investigator.errors.full_messages.join(', ')
  end
  
  def success_message
    "#{@investigator.name} has entered the world, crossing the threshold of ignorance into a terrifying knowledge of the forces which oppose mankind."
  end
  
  def retired_message
    "Few can escape the madness and damnation awaiting those who would seek the invisible forces governing our universe, but if you retire now you just might be able to return to a happy sheltered life and spend your remaining years forgetting the true horror of what you've learned."
  end
  
  def require_authorized_login
    return true unless current_user.blank?
    session[:investigator_params] = params[:investigator]
    render_and_respond :redirect, 
                       :message => "Please login with your Facebook account to continue.", 
                       :title => 'Facebook Connect', 
                       :to => oauth_authorize_path(:platform => 'facebook')
    return false
  end
  
  def investigator_params
    params[:investigator] || session[:investigator_params]
  end
  
  def require_no_investigator
    return true if current_user.blank? || current_user.investigator.blank?
    flash[:error] = "You already created an investigator."
    redirect_to edit_facebook_investigator_path and return false
  end  
  
  def show_html
    render_to_string(:layout => false, :template => "facebook/investigators/show.html")
  end  
end