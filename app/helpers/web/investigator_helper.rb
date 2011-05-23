module Web::InvestigatorHelper
  def owned_by_friend?(investigator)
    current_user && 
    current_user.facebook_friend_ids && 
    current_user.facebook_friend_ids.split(',').include?( investigator.user.facebook_id )
  end
end