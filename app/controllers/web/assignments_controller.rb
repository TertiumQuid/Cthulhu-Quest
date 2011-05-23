class Web::AssignmentsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def edit
    @assignment = current_investigator.requested_assignments(:open => false).find( params[:id] )
    @investigation = @assignment.investigation
    @plot = @investigation.plot
  end
  
  def update
    @assignment = current_investigator.requested_assignments.find( params[:id] )
    @assignment = Assignment.find( @assignment.id ) # unlock read-only
    
    if @assignment.respond!( params[:assignment] )
      notice = if @assignment.accepted?
        "You're now helping to investigate this plot"
      else
        "You've declined to help investigate this plot"
      end
      redirect_to web_casebook_index_path, :notice => notice and return
    else
      flash[:error] = @assignment.errors.full_messages.join(', ')
      redirect_to web_casebook_index_path
    end    
  end
end