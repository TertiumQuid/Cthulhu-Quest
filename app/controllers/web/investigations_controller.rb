class Web::InvestigationsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  before_filter :set_plot_thread
  
  def new
    @investigation = @plot_thread.investigations.build
    @investigation.build_assignments
    @prerequisites = @plot_thread.plot.prerequisites
    @rewards = @plot_thread.plot.rewards
    @allies = current_investigator.allies.ally
    @contacts = current_investigator.contacts.favorable.character
  end
  
  def create
    @investigation = @plot_thread.investigations.new( params[:investigation] )
    @investigation.set_assignment_owner
    
    if @investigation.save
      if @investigation.investigated?
        notice = "Your moxie precipitates the investigation of #{@plot_thread.plot.title} toward its conclusion. You may now attempt to solve the plot."
        redirect_to edit_web_casebook_investigation_path(@plot_thread, @investigation), :notice => notice and return
      elsif @investigation.active?
        notice = "Now investigating the #{@plot_thread.plot.title}. After #{@plot_thread.plot.duration} hours, you can return and attempt to solve the matter."
        redirect_to web_casebook_index_path, :notice => notice and return
      end
    else
      flash[:error] = @investigation.errors.full_messages.join(', ')
      redirect_to new_web_casebook_investigation_path(@plot_thread) and return
    end
  end
  
  def edit
    @investigation = find_for_edit( params[:id] )
    @assignments = @investigation.assignments
    @rewards = @plot_thread.plot.rewards
    @threats = @plot_thread.plot.threats
  end
  
  def complete
    @investigation = find_for_edit( params[:id] )
    
    if @investigation.complete!
      flash[:notice] = "Indeed, well done! "
      flash[:notice] = flash[:notice] + "You managed to #{@investigation.assignments.map(&:intrigue).map(&:title).join(', and ')}. "
      combat = @investigation.assignments.map(&:combat).select{|c| !c.nil? }
      flash[:notice] = flash[:notice] + "You were attacked also in the course of investigation; #{combat.map(&:result)} " unless combat.blank?
      flash[:notice] = flash[:notice] + "Now the intrigues have been put to rest, and you can now choose how you'd like to solve the plot."
      redirect_to edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
    else
      failures = @investigation.assignments.select{|a| !a.successful?}.map(&:intrigue).map(&:title)
      flash[:error] = "It was not to be. Defeated by fate and intrigue, you failed to #{failures.join(', and ')}. "
      combat = @investigation.assignments.map(&:combat).select{|c| !c.nil? }
      flash[:error] = flash[:error] + "Furthermore, you were attacked in the course of investigation; #{combat.map(&:result)} " unless combat.blank?
      flash[:error] = flash[:error] + "But don't lose heart, you can try again, and next time you'll be stronger."
      redirect_to web_casebook_path( @investigation.plot_thread_id )
    end
  end
  
  def solve
    @investigation = @plot_thread.investigations.completed.find( params[:id] )
    @solution = @plot_thread.plot.solutions.find_by_id( params[:solution_id] )
    
    if @investigation.solve!( @solution )
      flash[:notice] = "#{@investigation.plot_title} solved. You have chosen to #{@solution.description} "
      flash[:notice] = flash[:notice] + "As a reward you received " + @investigation.plot.rewards.map(&:reward_name).join(', and ')
      redirect_to web_casebook_investigation_path( @investigation.plot_thread_id )
    else
      flash[:error] = @investigation.errors.full_messages.join(', ')
      redirect_to edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
    end    
  end
  
  def hasten
    @investigation = find_for_edit( params[:id] )
    
    if @investigation.hasten!
      flash[:notice] = "Your relentless moxie drives the investigation to its end as you strike at the heart of the matter."
    else
      flash[:error] = @investigation.errors.full_messages.join(', ')
    end      
    redirect_to edit_web_casebook_investigation_path( @investigation.plot_thread_id, @investigation.id )
  end
  
  def destroy
    @investigation = find_for_edit( params[:id] )
    @investigation.destroy
    flash[:notice] = "You ended your investigation. The stars are not yet right."
    redirect_to web_casebook_index_path
  end
  
private

  def find_for_edit(id)
    return nil unless @plot_thread
    @plot_thread.investigations.ready.find_by_id( id ) ||
    Investigation.where(:plot_thread_id => @plot_thread.id).includes({:assignments => :intrigue}).active.elapse( id )
  end

  def set_plot_thread
    @plot_thread = current_investigator.casebook.find( params[:casebook_id] )
  end
end