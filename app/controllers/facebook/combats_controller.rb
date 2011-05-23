class Facebook::CombatsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  before_filter :init_monster
  
  def new
    @combat = @monster.combats.new(:investigator => current_investigator)
    @effections = current_investigator.effections.active.effect.on_combat if current_investigator
    
    render_and_respond :success, :title => "Hunting Monsters in #{@location.name}", :html => new_html
  end
  
  def create
    @combat = @monster.combats.create(:investigator_id => current_investigator.id)

    if @combat.succeeded?
      render_and_respond :redirect, :message => success_message, :title => 'Battled Monster and Survived', :html => show_html, :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Battled Monster and Lost', :html => show_html, :to => return_path
    end
  end
  
private

  def return_path
    fb_url( facebook_location_path )
  end

  def failure_message
    "You lost the battle and #{combat_log_concat}"
  end
  
  def success_message
    "#{combat_log_concat} You earned your bounty of £#{@monster.bounty}."
  end
  
  def combat_log_concat
    @combat.logs[@combat.logs.size - 2] + " " + @combat.logs[@combat.logs.size - 1]
  end

  def new_html
    render_to_string(:layout => false, :template => "facebook/combats/new.html")
  end
  
  def show_html
    render_to_string(:layout => false, :template => "facebook/combats/show.html")
  end  

  def init_monster
    @location = current_investigator.location
    @monster = @location.denizens.find_by_monster_id( params[:monster_id] ).monster
  end  
end