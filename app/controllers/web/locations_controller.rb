class Web::LocationsController < Web::WebController
  before_filter :require_user, :except => [:index]
  before_filter :require_investigator, :except => [:index]

  def index
  end
  
  def show
    @location = Location.find( params[:id] )
    @transits = @location.transits.includes(:destination)
    @denizens = @location.denizens.includes(:monster)
    @characters = @location.characters
    @plots = Plot.available_for(current_investigator).viable_for(current_investigator).located_at(@location.id)
  end
  
  def update
    if transit = Transit.travel!(current_investigator, params[:id])
      flash[:notice] = "Your travels aboard the #{transit.mode} begin as you depart for #{transit.destination.name}."
      redirect_to web_location_path( params[:id] )
    else
      flash[:error] = "Could not commence travel. "
      flash[:error] = flash[:error] + current_investigator.errors.full_messages.join(',') + "."
      redirect_to web_location_path( current_investigator.location_id )
    end
  end
end