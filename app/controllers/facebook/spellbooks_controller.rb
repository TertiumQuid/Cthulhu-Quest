class Facebook::SpellbooksController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def index
    @spellbooks = current_investigator.spellbooks.grimoire
    @spells = current_investigator.spells.effects
    @casting = current_investigator.castings.current
    @effections = current_investigator.effections.active.effect
    render_and_respond :success
  end
  
  def update
    @spellbook = current_investigator.spellbooks.unread.find( params[:id] )
    
    if @spellbook.read!
      render_and_respond :success, :message => success_message, :title => 'Read Grimoire', :to => return_path, :html => sanity_status
    else
      render_and_respond :success, :message => failure_message, :title => 'Read Grimoire and Driven Mad', :to => return_path, :html => sanity_status
    end
  end
  
private

  def sanity_status
    current_investigator ? current_investigator.madness_status : nil
  end

  def return_path
    facebook_spellbooks_path
  end

  def failure_message  
    "Heedless of your fraying mind, you read too obsessively to ignore the terrible profundities in the pages. You complete #{@spellbook.name}, but at the cost of (#{@spellbook.grimoire.madness_cost}) madness and an insanity."
  end

  def success_message
    "A scholar labors in the pages like a ploughman in the field. Your readings have brought enlightment and you complete #{@spellbook.name} with an understanding as great as any sage, yet oblivious to the albatross of (#{@spellbook.grimoire.madness_cost}) madness."
  end    
end