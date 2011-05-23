require 'ostruct'

AppConfig = OpenStruct.new
AppConfig.name = "Cthulhu Quest"
AppConfig.domain = "cthulhuquest.com"
AppConfig.version = '0.8.2'
AppConfig.updated_at = "April 30th, 2011"

fb = if Rails.env.production?
       {:app_id => '155345421154514', :app_key => 'd380f16d6396e1216ebc609602651341', :app_secret => '35acd0615f46701fb33cb8f516dfaffa'}
     elsif Rails.env.development?
       {:app_id => '155345421154514', :app_key => 'd380f16d6396e1216ebc609602651341', :app_secret => '35acd0615f46701fb33cb8f516dfaffa'}
     elsif Rails.env.test?
       {:app_id => '155345421154514', :app_key => 'd380f16d6396e1216ebc609602651341', :app_secret => '35acd0615f46701fb33cb8f516dfaffa'}
     end
  
AppConfig.facebook = OpenStruct.new(fb)
AppConfig.facebook.site = 'https://graph.facebook.com'

AppConfig.analytics = OpenStruct.new( {:ua => 'UA-19543048-1'} )