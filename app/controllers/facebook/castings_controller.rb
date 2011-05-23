class Facebook::CastingsController < Facebook::FacebookController
  include ActionView::Helpers::TextHelper
  
  before_filter :require_user
  before_filter :require_investigator
  
  def new
    @spell = current_investigator.spells.find( params[:spell_id] )
    @casting = current_investigator.castings.new :spell => @spell
    
    render_and_respond :success, :html => new_html, :title => "Perform the Rituals of #{@spell.name}"
  end
  
  def create
    @spell = current_investigator.spells.find( params[:spell_id] )
    @casting = current_investigator.castings.new( :spell => @spell )
    
    if @casting.save
      render_and_respond :success, :message => success_message, :title => 'Began the Rituals', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Perform Rituals', :to => return_path
    end    
  end
  
private

  def return_path
    facebook_spellbooks_path
  end
  
  def success_message
    "You have begun the demanding rituals for casting #{@spell.name}, which will take #{ pluralize(@spell.time_cost, 'hour') } to complete, after which you'll receive #{@spell.effect}."
  end

  def failure_message
    @casting.errors.full_messages.join(", ")
  end

  def new_html
    render_to_string(:layout => false, :template => "facebook/castings/new.html")
  end
end