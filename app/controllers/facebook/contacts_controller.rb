class Facebook::ContactsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
    
  def index
    @contacts = current_investigator.contacts.character
    @introductions = current_investigator.introductions.arranged
    render_and_respond :success
  end
  
  def show
    @contact = current_investigator.contacts.find( params[:id] )
    @plots = @contact.character.plots.available_for(current_investigator)
    @allies = current_investigator.allies.need_introduction_for( @contact.character_id ).without_contact_for( @contact.character_id )
    render_and_respond :success, :html => show_html, :title => "Contact: #{@contact.name}"
  end
  
  def entreat
    @contact = current_investigator.contacts.find( params[:id] )
    if @contact.entreat_favor!
      render_and_respond :success, :message => success_message, :title => 'Enreated Favor', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Entreat Favor', :to => return_path
    end    
  end
  
private

  def success_message
    "You met with #{@contact.name} and confided your worst fears, entreating their help in your luckless investigations. You gained +1 favor which may be used to assign your contact to help with a plot intrigue."
  end

  def failure_message
    if !@contact.entreatable?  
      "You cannot entreat your contact for more favor so soon; you must wait a decorous period."
    elsif !@contact.located?
      "You must travel to #{@contact.character.location.name} to entreat #{@contact.name}'s favor."
    end
  end    

  def return_path
    facebook_contact_path(@contact)
  end

  def show_html
    render_to_string(:layout => false, :template => "facebook/contacts/show.html")
  end
end