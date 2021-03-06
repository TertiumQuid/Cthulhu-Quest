class Facebook::JournalController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def show
    @journal = current_investigator.journal.includes(:activity).ordered.limit(50)
    render_and_respond :success
  end
end