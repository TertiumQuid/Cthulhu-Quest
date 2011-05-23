class Web::StatsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator

  def update
    @stat = current_investigator.stats.find_by_skill_id( params[:id] )
    skill_level = @stat.skill_level
    @stat.increment!
    
    if @stat.errors.empty?
      flash[:notice] = "Added +1 skill point to #{@stat.skill_name}"
      if skill_level < @stat.skill_level
        flash[:notice] = flash[:notice] + " and advanced to level #{@stat.skill_level}. Pour yourself a drink!" 
      else
        remains = @stat.next_level_skill_points - @stat.skill_points
        flash[:notice] = flash[:notice] + " and advanced one step on the road to mastery. "
        flash[:notice] = flash[:notice] + "#{remains} " + (remains > 1 ? 'points' : 'point') + " more until advancement."
      end
    else
      flash[:error] = @stat.errors.full_messages.join(', ')
    end
    
    redirect_to edit_web_investigator_path
  end
end