class Web::CastingsController < Web::WebController
  include ActionView::Helpers::TextHelper
  
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @spell = current_investigator.spells.find( params[:spell_id] )
    @casting = current_investigator.castings.new( :spell => @spell )
    
    if @casting.save
      notice = "You have begun the demanding rituals for casting #{@spell.name}, "
      notice = notice + "which will take #{ pluralize(@spell.time_cost, 'hour') } to complete."
      redirect_to web_spellbooks_path, :notice => notice and return
    else
      flash[:error] = @casting.errors.full_messages.join(', ')
      redirect_to web_spellbooks_path and return
    end    
  end
end