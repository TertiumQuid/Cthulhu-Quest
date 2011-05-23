class Facebook::StatsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def update
    @stat = current_investigator.stats.find_or_initialize_by_skill_id( params[:id] )
    @original_skill_level = @stat.skill_level
    @stat.increment!( params[:skill_points] || 1 )

    if @stat.errors.empty?
      render_and_respond :success, :message => success_message, :title => 'Added Skill Points', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could Not Add Point', :to => return_path
    end    
  end
  
private

  def return_path
    edit_facebook_investigator_path
  end  
  
  def failure_message
    @stat.errors.full_messages.join(", ")
  end

  def success_message
    "Added +#{(params[:skill_points] || 1)} skill point#{( (params[:skill_points] || 1).to_i > 1 ? 's' : '' )} to #{@stat.skill_name}" +
      (advanced_skill? ? " and advanced to level #{@stat.skill_level}. Pour yourself a drink!" :
       " and advanced one step on the road to mastery. #{(@stat.next_level_skill_points - @stat.skill_points)} " + (@stat.next_level_skill_points - @stat.skill_points > 1 ? 'points' : 'point') + " more until advancement.")
  end    
  
  def advanced_skill?
    @original_skill_level < @stat.skill_level
  end
end