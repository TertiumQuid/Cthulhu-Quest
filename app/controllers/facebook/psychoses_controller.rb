class Facebook::PsychosesController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def update
    @psychosis = current_investigator.psychoses.find(params[:id])
    
    if @psychosis.begin_treatment!
      render_and_respond :success, :message => treating_message, :title => 'Committed to Asylum', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Begin Treatment', :to => return_path
    end
  end
  
  def destroy
    @psychosis = current_investigator.psychoses.treatable.find(params[:id])
    
    if @psychosis.finish_treatment!
      render_and_respond :success, :message => treated_message, :title => 'Asylum Treatment Succeeded', :to => return_path, :json => madness_status
    else
      render_and_respond :failure, :message => untreated_message, :title => 'Asylum Institutionalization Traumatizing', :to => return_path
    end    
  end
  
private 

  def return_path
    edit_facebook_investigator_path
  end  
  
  def failure_message
    @psychosis.errors.full_messages.join(', ')
  end  
  
  def treating_message
    "You have institutionalized yourself in the grim care of the asylum. Expect to suffer fever theorapy, potent drugs, electroshock, and behaviorist mind games as you battle the crippling condition of #{@psychosis.name}."
  end  
  
  def treated_message
    "The severe treatments of the asylum physicians have traumatized away the crippling duress of your #{@psychosis.degree} #{@psychosis.name}."
  end  
  
  def untreated_message
    "The best efforts of dedicated asylum physcians was unable to cure you of the #{@psychosis.degree} #{@psychosis.name}, releasing you to the world phsycially worse for your time in the institution and mentally no better."
  end  
  
  def madness_status
    current_investigator ? current_investigator.madness_status : nil
  end  
end