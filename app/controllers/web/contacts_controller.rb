class Web::ContactsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def show
    @contact = current_investigator.contacts.find( params[:id] )
    @allies = current_investigator.allies.need_introduction_for( @contact.character_id )
  end
  
  def entreat
    @contact = current_investigator.contacts.find( params[:id] )
    if @contact.entreat_favor!
      notice = "You met with #{@contact.name} and confided your worst fears, entreating their help in your luckless investigations. "
      notice = notice + "You gained +1 favor which may be used to assign your contact to help with a plot intrigue."
      redirect_to web_contact_path(@contact), :notice => notice
    else  
      flash[:error] = if !@contact.entreatable?  
        "You cannot entreat your contact for more favor so soon; you must wait a decorous period."
      elsif !@contact.located?
        "You must travel to #{@contact.character.location.name} to entreat #{@contact.name}'s favor."
      end  
      redirect_to web_contact_path(@contact)
    end
  end
end