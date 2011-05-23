class Facebook::PlotThreadsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  before_filter :init_plot, :only => [:create]
  
  def index
    @assignments = current_investigator.requested_assignments
    @plot_threads = current_investigator.casebook.available.plot
    @solved_plots = current_investigator.casebook.solved.solution.plot
    @item_ids = current_investigator.item_ids
    
    @investigation = current_investigator.investigations.open.assignments.first
    if @investigation
      @investigation.elapse! if @investigation.elapsed?
      @completed_assignments = @investigation.plot_thread.assignments.successful
      @psychoses = current_investigator.psychoses.insanity 
    end
    
    render_and_respond :success
  end
  
  def create
    @plot_thread = current_investigator.casebook.new(:plot => @plot)
    if @plot_thread.save
      render_and_respond :success, :message => success_message, :title => 'Added plot', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not add plot', :to => return_path
    end 
  end
  
private

  def return_path
    facebook_casebook_index_path
  end    
  
  def failure_message
    @plot_thread.errors.full_messages.join(', ')
  end

  def success_message
    "You have accepted the plot, #{@plot.title}, and may attempt to investigate it when you are duly prepared."
  end    
  
  def init_plot
    @plot = Plot.available_for(current_investigator)
    @plot = if params[:contact_id] 
      contact = Contact.find( params[:contact_id] )
      @plot.assigned_by( contact.character_id )
    else
      @plot.located_at( current_investigator.location_id )
    end
    
    @plot = @plot.find_by_id( params[:id] )
  end
end