class Web::SpellbooksController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator

  def index
    @spellbooks = current_investigator.spellbooks.grimoire
    @read_spellbooks = @spellbooks.select{|s| s.read? }
    @unread_spellbooks = @spellbooks.select{|s| !s.read? }
    
    @spells = current_investigator.spells
    @castings = current_investigator.castings.active
  end
  
  def update
    @spellbook = current_investigator.spellbooks.unread.find( params[:id] )
    
    if @spellbook.read!
      flash[:notice] = "Heedless of your fraying mind, you read too obsessively to ignore the terrible profundities in the pages. "
      flash[:notice] = flash[:notice] + "You complete #{@spellbook.name}, but at the cost of (#{@spellbook.grimoire.madness_cost}) madness and an insanity."
    else
      flash[:notice] = "A scholar labors in the pages like a ploughman in the field. "
      flash[:notice] = flash[:notice] + "Your readings have brought enlightment and you complete #{@spellbook.name} with an understanding as great as any sage, "
      flash[:notice] = flash[:notice] + "yet oblivious to the albatross of (#{@spellbook.grimoire.madness_cost}) madness."
    end
    redirect_to web_spellbooks_path
  end
end