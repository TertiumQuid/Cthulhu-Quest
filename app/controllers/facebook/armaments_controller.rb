class Facebook::ArmamentsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def purchase
    @weapon = Weapon.dry_goods.find( params[:id] )
    @armament = current_investigator.armaments.purchase!( @weapon )
    
    if !@armament.new_record?
      render_and_respond :success, :message => success_message, :title => 'Purchased weapon', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not purchase weapon', :to => return_path
    end    
  end
  
  def update
    @armament = current_investigator.armaments.equip!( params[:id] )
    
    render_and_respond :success, :message => armed_message, :title => 'Equipped Weapon', :to => return_path
  end  
  
private

  def return_path
    facebook_items_path
  end  
  
  def armed_message
    "#{@armament.weapon_name} armed and readied."
  end
  
  def failure_message
    @armament.errors.full_messages.join(", ")
  end

  def success_message
    "Purchased #{@weapon.name} for £#{@weapon.price}"
  end    
end