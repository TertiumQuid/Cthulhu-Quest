class Web::JournalController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def show
    @journal = current_investigator.journal.includes(:activity).ordered.limit(50)
  end
end