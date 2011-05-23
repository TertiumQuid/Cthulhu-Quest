require File.expand_path('../boot', __FILE__)

require 'rails/all'
require File.expand_path('../../lib/facebook/facebook_graph', __FILE__)

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module CthulhuQuest
  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    require 'rack/facebook_posts'
    
    config.middleware.use Rack::FacebookPosts
    
    config.autoload_paths << File.join(config.root, "lib") 
    
    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Verbose logging
    config.log_level = :debug

    google_cdn = 'http://ajax.googleapis.com/ajax/libs/'
    config.action_view.javascript_expansions[:defaults] = [ "#{google_cdn}jquery/1.5.1/jquery.min.js", 
                                                            "#{google_cdn}jqueryui/1.8.9/jquery-ui.min.js", 
                                                            "rails", "application" ]

    config.action_view.stylesheet_expansions[:defaults] = [ "reset", 
                                                            "#{google_cdn}jqueryui/1.8.9/themes/mint-choc/jquery-ui.css", 
                                                            "facebook" ]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    
    # redefine automatic error labels to exclude special error markup
    ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
      html_tag
    end      
  end
end
