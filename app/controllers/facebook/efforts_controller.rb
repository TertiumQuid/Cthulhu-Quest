class Facebook::EffortsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @tasking = current_investigator.location.taskings.find(params[:tasking_id])
    @effort = current_investigator.efforts.new(:tasking => @tasking)
    
    if @effort.save
      render_and_respond :success, :message => success_message, :title => 'Task Completed', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not send gift', :to => return_path
    end
  end
  
private

  def return_path
    facebook_location_path
  end

  def failure_message
    @effort.errors.full_messages.join(", ")
  end
  
  def success_message
    if @effort.succeeded?
      rewarded_message
    else
      unrewarded_message
    end
  end

  def rewarded_message
    "You completed the task #{@tasking.task.name} and earned #{@tasking.reward_name}"    
  end  
  
  def unrewarded_message
    "You failed to complete the task #{@tasking.task.name}, earning nothing"    
  end
end