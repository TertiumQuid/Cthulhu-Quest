module Web::WebHelper
  def link_to_facebook(user)
    link_to image_tag( 'facebook-icon.png' ), 
            "http://www.facebook.com/profile.php?id=#{user.facebook_id}",
            :target => '_blank'
  end
  
  def link_to_add_facebook_friend(user)
    link_to "Befriend on \"The Facebook\"", 
            "http://www.facebook.com/addfriend.php?id=#{user.facebook_id}",
            :target => '_blank'
  end  
end