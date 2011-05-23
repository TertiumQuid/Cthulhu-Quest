class Web::CharactersController < Web::WebController
  before_filter :redirect_for_contact
  
  def show
    @character = Character.find(params[:id])
  end
  
private

  def redirect_for_contact
    return if current_investigator.blank?
    
    if contact_id = character_to_contact_id
      redirect_to web_contact_path( contact_id )
    end
  end  
  
  def character_to_contact_id
    if current_investigator && current_investigator.contacts.where(:character_id => params[:id]).exists?
      current_investigator.contacts.where(:character_id => params[:id]).first.id
    else
      nil
    end
  end
end