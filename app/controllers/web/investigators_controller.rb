class Web::InvestigatorsController < Web::WebController
  before_filter :require_user, :except => [:show]
  before_filter :require_investigator, :except => [:new,:create,:show]
  before_filter :require_no_investigator, :only => [:new,:create]

  def show
    @investigator = Investigator.find(params[:id])
  end
  
  def new
    @investigator = current_user.build_investigator(flash[:investigator])
    @profiles = Profile.order('name ASC').all
  end
  
  def create
    @investigator = current_user.build_investigator(params[:investigator])
    if @investigator.save
      redirect_to edit_web_investigator_path, :notice => "Your investigator lives and breathes" and return
    else
      flash[:investigator] = params[:investigator]
      flash[:error] = @investigator.errors.full_messages.join(', ')
      redirect_to new_web_investigator_path and return
    end
  end
  
  def edit
    @investigator = current_investigator
    @equipment = @investigator.possessions.items.inventory.order('item_name')
    @books = @investigator.possessions.items.books.order('item_name')
    @armaments = @investigator.armaments.weapons.order('weapon_name')
  end
  
  def heal
    @possession = current_investigator.possessions.items.medical.first
    @investigator = current_investigator.heal!( @possession, params[:id] )
    if @investigator.errors[:wounds].empty?
      if params[:id]
        flash[:notice] = "You meet with #{@investigator.name} and treat each other's wounds."
      else
        flash[:notice] = "The mercy of modern medical science treats your wounds."
      end
    else      
      flash[:error] = @investigator.errors.full_messages.join(', ')
    end
    redirect_to (params[:id] ? web_investigator_path(params[:id]) : edit_web_investigator_path)
  end
  
private
  def require_no_investigator
    return true if current_user.investigator.blank?
    flash[:error] = "You already created an investigator."
    redirect_to edit_web_investigator_path and return false
  end  
end