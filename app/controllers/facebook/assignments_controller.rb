class Facebook::AssignmentsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def update
    @assignment = current_investigator.requested_assignments.find( params[:id] )
    if @assignment.respond!( params[:assignment] )
      render_and_respond :success, :message => (@assignment.accepted? ? accepted_message : declined_message), :title => "Answered Request", :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => "Could not respond", :to => return_path
    end    
  end

private

  def return_path
    facebook_casebook_index_path
  end  

  def failure_message
    @assignment.errors.full_messages.join(', ')
  end

  def accepted_message
    "You're now helping your ally to investigate an intrigue, and #{@assignment.intrigue.title}"
  end  
  
  def declined_message
    "You declined to help your ally #{@assignment.intrigue.title}"
  end
end