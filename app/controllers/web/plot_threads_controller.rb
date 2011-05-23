class Web::PlotThreadsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator

  def index
    @assignments = current_investigator.requested_assignments
    @plot_threads = current_investigator.casebook.available.plot
    @solved_plots = current_investigator.casebook.solved
    @active_investigations = current_investigator.investigations.active.elapse_all
    @ready_investigations = current_investigator.investigations.ready
  end
  
  def show
    @plot_thread = current_investigator.casebook.includes(:investigations => :assignments).find( params[:id] )
    @unsolved_investigations = @plot_thread.investigations.select{|i| i.status=='unsolved'}
    @solved_investigation = @plot_thread.investigations.select{|i| i.status=='solved'}.first
    @rewards = @plot_thread.plot.rewards
    @prerequisites = @plot_thread.plot.prerequisites
    @threats = @plot_thread.plot.threats
  end
  
  def create
   @plot = Plot.available_for(current_investigator).located_at( current_investigator.location_id ).find_by_id( params[:id] )
   @plot_thread = current_investigator.casebook.new(:plot => @plot) if @plot
   
   if @plot_thread.blank?
      flash[:error] = "Couldn't find available plot"
      redirect_to web_casebook_index_path and return
   elsif @plot_thread.save
     redirect_to web_casebook_index_path, :notice => "You have accepted the plot, #{@plot.title}, and may attempt to investigate it when you are duly prepared." and return
   else
     flash[:error] = @plot_thread.errors.full_messages.join(', ')
     redirect_to web_casebook_index_path and return
   end
  end
end