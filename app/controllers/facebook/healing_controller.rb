class Facebook::HealingController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def show
    @items = item_list
    @investigator = Investigator.find( params[:investigator_id] ) unless healing_self?
    
    render_and_respond :success, :html => show_html, :title => show_title
  end
  
  def create
    @possession = item
    @investigator = Investigator.find( params[:investigator_id] ) unless healing_self?
    
    unless @possession.blank?
      @possession.use!(@investigator)
      render_and_respond :success, :message => success_message, :title => create_title, :json => investigator_status, :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Administer Treatment', :to => return_path
    end
  end
  
private

  def item_list
    if params[:kind] == 'spirit' 
      current_investigator.possessions.items.spirit.order('item_name')
    else
      current_investigator.possessions.items.medical.order('item_name')
    end
  end
  
  def item
    if params[:kind] == 'spirit'
      current_investigator.possessions.items.spirit.find_by_id(params[:id])
    else
      current_investigator.possessions.items.medical.find_by_id(params[:id])
    end
  end

  def show_title
    params[:kind] == 'spirit' ? 'Administer Calming Drink' : 'Administer Medical Treatment'
  end
  
  def create_title
    params[:kind] == 'spirit' ? 'Becalmed a Troubled Mind' : 'Treated Wounds'
  end

  def success?
    @investigator.blank? || @investigator.errors.empty?
  end

  def return_path
    healing_self? ? edit_facebook_investigator_path : facebook_investigator_path(@investigator)
  end
  
  def failure_message
    "Could not find item among your possessions"
  end
  
  def success_message
    if params[:kind] == 'spirit'
      if healing_self?
        "You sip until your hands steady and your mind calms, finding a much-needed tranquility in the still waters of a stiff drink."
      elsif @investigator
        "You meet with #{@investigator.name} and find that sharing a drink regroups the mind and leaves you becalmed."
      end
    else
      if healing_self?
        "You treat your wounds with the tools of modern medical science."
      elsif @investigator
        "You meet with #{@investigator.name} and treat each other's wounds."
      end
    end    
  end  
  
  def healing_self?
    current_investigator.id.to_s == (params[:investigator_id] || '').to_s
  end

  def investigator_status
    if params[:kind] == 'spirit'
      healing_self? ? current_investigator.reload.madness_status : (@investigator ? @investigator.madness_status : nil)
    else
      healing_self? ? current_investigator.wound_status : (@investigator ? @investigator.wound_status : nil)
    end
  end  
  
  def show_html
    render_to_string(:layout => false, :template => "facebook/healing/show.html")
  end  
end