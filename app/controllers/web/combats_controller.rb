class Web::CombatsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  before_filter :init_monster
  
  def new
    @combat = @monster.combats.new(:investigator => current_investigator)
  end
  
  def create
    @combat = @monster.combats.create(:investigator_id => current_investigator.id)
    
    if @combat.succeeded?
      redirect_to web_location_path(@location), :notice => "#{@combat.logs.last} You earned your bounty of £#{@monster.bounty}."
    else
      redirect_to web_location_path(@location), :notice => "You lost the battle and #{@combat.logs.last}"
    end
  end
  
private

  def init_monster
    @location = current_investigator.location
    @monster = @location.denizens.find_by_monster_id( params[:monster_id] ).monster
  end  
end