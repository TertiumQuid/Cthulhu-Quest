module Web::PlotThreadHelper
  def helpers(investigation)
    text = "<li><div class='body' style='min-height:60px;'><br /><label>"
    assignments = investigation.assignments.select {|a| a.ally_assigned? }
    
    return "#{text}You're investigating this alone</label></div></li>" if assignments.blank?
    
    helping = []
    assignments.each do |a|
      if a.requested?
        helping << "waiting on help from #{a.ally.name} "
      elsif a.refused?
        helping << "#{a.ally.name} declined to help "
      else
        helping << "#{a.ally.name} is helping "
      end
    end
    text = text + helping.join(",")
		text = text + ".</label></div></li>"
		return text
  end
  
  def link_to_assignment_investigator(assignment)
    return unless current_investigator && assignment
    
    thread = assignment.investigation.plot_thread
    own_plot = (thread.investigator_id == current_investigator.id)
    own_assignment = (assignment.investigator_id == current_investigator.id)
    
    text = if own_plot && own_assignment
      "You investigated this yourself."
    elsif own_plot && !own_assignment
      raw("#{link_to(assignment.investigator.name, web_investigator_path(assignment.investigator))} helped you investigate this.")
    elsif own_assignment
      raw("You helped #{link_to(thread.investigator.name,web_investigator_path(thread.investigator))} investigate this.")
    end
    return text
  end
end