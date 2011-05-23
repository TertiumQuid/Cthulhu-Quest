class Web::PossessionsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator

  def purchase
    @item = Item.purchasable.find( params[:id] )
    @possession = current_investigator.possessions.purchase!( @item )
    
    if @possession.new_record?
      flash[:error] = @possession.errors.full_messages.join(', ')
      redirect_to web_items_path and return
    else
      redirect_to web_items_path, :notice => "Purchased #{@item.name} for £#{@item.price}" and return
    end
  end
  
  def use
  end
  
  def destroy
    @possession = current_investigator.possessions.find( params[:id] )
    @possession.destroy
    redirect_to edit_web_investigator_path, :notice => "#{@possession.item_name} destroyed" and return
  end
end