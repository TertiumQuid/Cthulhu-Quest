class Facebook::InvestigationsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def new
    @plot_thread = current_investigator.casebook.find(params[:casebook_id])
    @investigation = @plot_thread.investigations.new
    @investigation.build_assignments
    @completed_assignments = @investigation.plot_thread.assignments.successful
    @allies = current_investigator.allies.ally
    @contacts = current_investigator.contacts.favorable.character
    
    render_and_respond :success, :html => new_html, :title => "Investigate: #{@plot_thread.plot_title}"
  end
  
  def create
    @plot_thread = current_investigator.casebook.find( params[:casebook_id] )
    @investigation = @plot_thread.investigations.new( params[:investigation] )
    @investigation.set_assignment_owner
    
    if @investigation.save
      render_and_respond :success, :message => success_message, :title => 'Investigating plot', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not begin investigation', :to => return_path
    end
  end
  
  def update
    @plot_thread = current_investigator.casebook.find( params[:casebook_id] )
    @investigation = @plot_thread.investigations.ready.find( params[:id] )
    @completed_assignments = @investigation.plot_thread.assignments.where("investigation_id <> #{@investigation.id}").successful
    
    if @investigation.advance_state!( params[:solution_id] ? params[:solution_id].to_i : nil )
      render_and_respond :success, :message => advanced_message, :title => 'Completed Investigation', :html => advanced_html, :to => return_path
    elsif @investigation.unsolved?
      render_and_respond :success, :message => unsolved_message, :title => 'Failed Investigation', :html => advanced_html, :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not advance investigation', :to => return_path
    end
  end
  
private
  def new_html
    render_to_string(:layout => false, :template => "facebook/investigations/new.html")
  end
  
  def advanced_html
    @investigation.solved? ? nil : render_to_string(:layout => false, :template => "facebook/investigations/_investigated.html")
  end

  def return_path
    fb_url( facebook_casebook_index_path )
  end  

  def failure_message
    @investigation.errors.full_messages.join(', ')
  end

  def success_message
    if @investigation.investigated?
      "Your moxie precipitates the investigation of #{@plot_thread.plot.title} toward its conclusion. You may now attempt to solve the plot."
    elsif @investigation.active?
      "Now investigating #{@plot_thread.plot.title}. After #{@plot_thread.plot.duration} hours, you can return and attempt to solve the matter. In the meanwhile, any allies you've assigned will have a chance to offer their help."
    end
  end  
  
  def advanced_message
    msg = ''
    if @investigation.completed?
      intrigues = @investigation.assignments.map(&:intrigue).map(&:title).join(', and ')
      combat = @investigation.assignments.map(&:combat).select{|c| !c.nil? }
      msg = "Indeed, well done! You managed to #{intrigues}. "
      msg = msg + "You were attacked also in the course of investigation; #{combat.map(&:result)} " unless combat.blank?
      msg = msg + "Now the intrigues have been put to rest, and you can now choose how you'd like to solve the plot."
    elsif @investigation.solved?
      @solution = Solution.find( params[:solution_id] )
      msg = "#{@investigation.plot_title} solved. You have chosen to #{@solution.description} As a reward you received " + @investigation.plot.rewards.map(&:reward_name).join(', and ')
    end
    msg
  end
  
  def unsolved_message
    failures = @investigation.assignments.select{|a| !a.successful?}.map(&:intrigue).map(&:title)
    combat = @investigation.assignments.map(&:combat).select{|c| !c.nil? }
    msg = "It was not to be. Defeated by fate and intrigue, you failed to #{failures.join(', and ')}. "
    msg = msg + "Furthermore, you were attacked in the course of investigation; #{combat.map(&:result)} " unless combat.blank?
    msg = msg + "But don't lose heart, you can try again, and next time you'll be stronger."
    msg
  end
  
  def assignments_json
    @investigation.assignments.to_json(:include => :intrigue)
  end
end