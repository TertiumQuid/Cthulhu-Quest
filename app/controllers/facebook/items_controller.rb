class Facebook::ItemsController < Facebook::FacebookController
  def index
    @items = sorted_items Item.dry_goods
    @weapons = sorted_items Weapon.dry_goods
    @artifacts = sorted_items Item.artifacts
    
    if current_investigator
      @weapon_ids = current_investigator.armaments.map(&:weapon_id)
      @item_ids = current_investigator.possessions.map(&:item_id)
    end
    
    render_and_respond :success
  end
  
private

  def sorted_items(items)
    items.all.sort! { |a,b| a.name <=> b.name }
  end  
end