class Web::ItemsController < Web::WebController
  def index
    @items = Item.dry_goods.order('items.name ASC').all
  end
  
  def artifacts
    @items = Item.artifacts.order('items.name ASC').all
  end  
end