source 'http://rubygems.org'

gem 'rails', '3.0.7'
gem 'oauth2'
gem 'json'
gem 'flexmock'
gem 'heroku', ">= 1.17.16"

group :development do
  gem 'mysql2'
  gem "query_reviewer", :git => "git://github.com/nesquena/query_reviewer.git"
end

group :test do
  gem 'mysql2'
end

group :production do
  gem "exception_notification", :git => "git://github.com/rails/exception_notification", :require => 'exception_notifier'
end