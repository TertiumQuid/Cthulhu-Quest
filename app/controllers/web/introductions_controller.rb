class Web::IntroductionsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @contact = current_investigator.contacts.find( params[:contact_id] )
    @investigator = current_investigator.inner_circle.find_by_id( params[:investigator_id] )
    @introduction = current_investigator.introducings.new(:character_id => @contact.character_id, 
                                                          :investigator_id => @investigator ? @investigator.id : nil )
    if @introduction.save
      notice = "Earnestly vouching the quality and character of your trusted friend, #{@investigator.name}, "
      notice = notice + "your arrange for #{@contact.name} to meet them on your good word. "
      notice = notice + "If they accept the introduction you'll receive a measure of experience, yet should they "
      notice = notice + "rudely dismiss your gesture your contact will hold you accountable."
      flash[:notice] = notice
    else
      flash[:error] = @introduction.errors.full_messages.join(', ')
    end  

    redirect_to web_contact_path(@contact) and return                                                          
  end
  
  def update
    @introduction = current_investigator.introductions.arranged.find( params[:id] )
    @introduction.accept!
    
    notice = "You've graciously accepted introductions with #{@introduction.character.name} "
    notice = notice + "and can now call upon them as one of your contacts."
    flash[:notice] = notice
    
    redirect_to web_allies_path and return
  end
  
  def destroy
    @introduction = current_investigator.introductions.arranged.find( params[:id] )
    @introduction.dismiss!
    notice = "You've cooly avoided introductions with #{@introduction.character.name}, "
    notice = notice + "a slight which may not go unnoticed."
    flash[:notice] = notice
    
    redirect_to web_allies_path and return
  end
end