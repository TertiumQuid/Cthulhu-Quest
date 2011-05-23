class Facebook::IntroductionsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator

  def create
    @contact = current_investigator.contacts.find( params[:contact_id] )
    @investigator = current_investigator.inner_circle.find_by_id( params[:investigator_id] )
    @introduction = current_investigator.introducings.new(:character_id => @contact.character_id, 
                                                          :investigator_id => params[:investigator_id] )
                                                          
    if @introduction.save
      render_and_respond :success, :message => success_message, :title => 'Sent Introduction', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Send Introduction', :to => return_path
    end    
  end
  
  def update
    @introduction = current_investigator.introductions.arranged.find( params[:id] )
    
    if @introduction.accept!
      render_and_respond :success, :message => acceptance_message, :title => 'Accepted Introduction', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Accept Introduction', :to => return_path
    end    
  end
  
  def destroy
    @introduction = current_investigator.introductions.arranged.find( params[:id] )
    @introduction.dismiss!
    
    render_and_respond :success, :message => refusal_message, :title => 'Refused Introduction', :to => return_path
  end
  
private

  def return_path
    if action_name == 'create'
      facebook_contacts_path
    else
      facebook_character_path(@introduction.character_id)
    end
  end  
  
  def acceptance_message
    "You've graciously accepted introductions with #{@introduction.character.name} and can now call upon them as one of your contacts."
  end
  
  def refusal_message
    "You've cooly avoided introductions with #{@introduction.character.name}, a slight which shall not go happily unnoticed."
  end

  def failure_message
    @introduction.errors.full_messages.join(', ')
  end  
  
  def success_message
    "Earnestly vouching the quality and character of your trusted friend, #{@investigator.name}, you arrange for #{@contact.name} to meet them on your good word. If they accept the introduction you'll receive a measure of experience, yet should they rudely dismiss your gesture your contact will hold you accountable."
  end
end