class Facebook::CharactersController < Facebook::FacebookController
  def show
    @character = Character.find(params[:id])
    @introduction = current_investigator.introductions.arranged.find_by_character_id(params[:id]) if current_investigator
    
    render_and_respond :success, :html => show_html, :title => "#{@character.profession}: #{@character.name}"
  end

private
  
  def show_html
    render_to_string(:layout => false, :template => "facebook/characters/show.html")
  end
end