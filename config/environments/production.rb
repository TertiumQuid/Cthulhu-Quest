CthulhuQuest::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  config.serve_static_assets = true
  
  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  google_cdn = 'http://ajax.googleapis.com/ajax/libs/'
  config.action_view.javascript_expansions[:defaults] = [ "#{google_cdn}jquery/1.5.1/jquery.min.js", 
                                                          "#{google_cdn}jqueryui/1.8.9/jquery-ui.min.js", 
                                                          "rails", "application" ]

  config.action_view.stylesheet_expansions[:defaults] = [ "reset", 
                                                          "#{google_cdn}jqueryui/1.8.9/themes/mint-choc/jquery-ui.css", 
                                                          "facebook" ]
        
  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.middleware.use ::ExceptionNotifier,
    :email_prefix => "[Cthulhu Quest Err] ",
    :sender_address => %{"notifier" <notifier@cthulhuquest.com>},
    :exception_recipients => %w{dunn.travis@gmail.com}  
end
