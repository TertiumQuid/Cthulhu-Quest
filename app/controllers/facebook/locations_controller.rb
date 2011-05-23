class Facebook::LocationsController < Facebook::FacebookController
  before_filter :require_user, :except => [:show]
  before_filter :require_investigator, :except => [:show]
  
  def show
    @location = current_investigator ? current_investigator.location : default_location
    @transits = @location.transits.includes(:destination => {:transits => :destination})
    @characters = @location.characters.location
    @denizens = @location.denizens.monster
    @taskings = @location.taskings.task
    
    if current_investigator
      @contacts = current_investigator.contacts.located_at( @location.id )
      @plots = Plot.available_for(current_investigator).located_at(@location.id).order("level ASC").all
      @introductions = current_investigator.introductions.arranged
      @taskings = @taskings.select {|t| t.viable_for?(current_investigator)}
    end
    
    render_and_respond :success
  end
  
  def update
    @transit = Transit.travel!(current_investigator, params[:id])
    if @transit != false
      render_and_respond :success, :message => success_message, :title => 'Traveling', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Travel', :to => return_path
    end
  end
  
private 

  def return_path
    facebook_location_path
  end  

  def failure_message
    current_investigator.errors.full_messages.join(',') + "."
  end

  def success_message
    "Your travels aboard the #{@transit.mode} begin as you depart for #{@transit.destination.name}."
  end

  def default_location
    Location.find_by_name('Arkham')
  end  
end