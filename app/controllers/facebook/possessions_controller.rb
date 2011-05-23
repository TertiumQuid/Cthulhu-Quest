class Facebook::PossessionsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def purchase
    @item = Item.purchasable.find( params[:id] )
    @possession = current_investigator.possessions.purchase!( @item )
    
    if !@possession.new_record?
      render_and_respond :success, :message => success_message, :title => 'Purchased item', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not purchase item', :to => return_path
    end    
  end
  
  def update
    @possession = current_investigator.possessions.find( params[:id] )
    
    if @possession.use!
      render_and_respond :success, :message => used_message, :title => used_title, :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not use item', :to => return_path
    end    
  end
  
private

  def return_path
    if action_name == 'update'
      edit_facebook_investigator_path
    else
      facebook_items_path
    end
  end  
  
  def used_message
    if @possession.item.book?
      "Studied book and gained +1 moxie for your increased enlightenment."
    elsif @possession.item.activatable?
      "Activated item, which #{@possession.item.effect_names}"
    end
  end
  
  def used_title
    if @possession.item.book?
      'Studied Book'
    elsif @possession.item.activatable?
      'Activated Item'
    end
  end
  
  def failure_message
    @possession.errors.full_messages.join(", ")
  end

  def success_message
    "Purchased #{@item.name} for £#{@item.price}"
  end    
end