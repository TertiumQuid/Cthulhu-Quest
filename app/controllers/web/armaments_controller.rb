class Web::ArmamentsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator

  def purchase
    @weapon = Weapon.dry_goods.find( params[:id] )
    @armament = current_investigator.armaments.purchase!( @weapon )
    
    if @armament.new_record?
      flash[:error] = @armament.errors.full_messages.join(', ')
      redirect_to web_weapons_path and return
    else
      redirect_to web_weapons_path, :notice => "Purchased #{@weapon.name} for £#{@weapon.price}" and return
    end
  end
  
  def update
    @armament = current_investigator.armaments.equip!( params[:id] )
    redirect_to edit_web_investigator_path, :notice => "#{@armament.weapon_name} armed and readied." and return
  end 
end