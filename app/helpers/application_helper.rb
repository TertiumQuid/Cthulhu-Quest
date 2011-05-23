module ApplicationHelper
  def fb_like_button
    raw "<fb:like layout=\"button_count\" show_faces=\"false\" font=\"trebuchet ms\" colorscheme=\"dark\"></fb:like>"
  end
  
  def fb_login_button
    raw "<fb:login-button show-faces=\"false\" width=\"200\" max-rows=\"1\" params=\"email,offline_access\" onlogin=\"top.location = json.to;\">Login to Play</fb:login-button>"
  end
end
