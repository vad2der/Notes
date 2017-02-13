# in order to run the console with project environment
rails console # or
rails c

# to list all classes in models, even if they are not using ORMs
Dir['**/models/**/*.rb'].map {|f| File.basename(f, '.*').camelize.constantize }

# run server in current folder
ruby -run -e httpd . -p 9090

# create rails-api (gem rails-api should be instaled prior to that)
rails-api new . -T -d sqlite3
# . - in current directory
# -T - without test
# -d sqlite - specifying database to use (-d postgresql)

#rspec generation
rails g rspec:request APIDevelopment
# will create spec/request/api_development_spec.rb with description "ApiDevelopment"



# ALTERNATIVE SERVERS
# for example PUMA
# add to Gemfile
gem 'puma', '~>3.6', '>=3.6.0', :platforms=>:ruby # some error messaging not inmlemented if run in windows
# if on windows, stay with WEBrick at least while developng
group :development do
  gem 'webrick', '~>1.3', '>=1.3.1', :platforms=>[:mingw, :mswin, :x64_mingw, :jruby]
end
# find configuration on https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#config
# save file config/puma.rb

# AUTH
# 1 Add devise gem into the Gemfile
# gem 'devise_token_auth', '~>1', '>=0.1.39'
# 2 update bundle
bundle
# 3 install/generate devise_token into app
rails g devise_token_auth:install User auth
# 4 in created model comment 
:confirmable
# by now since email system is not developed yet and and
:omniauth
# - for open ID authentication
# 5 in config devise_token_auth.rb uncomment
config.change_headers_on_each_request = true
# 6 in config devise.rb
Devise.setup do |config|
  #config.email_regexp = /\A[^@\s]+@[^@\s]+\z/ # - uncomment if there is an error on email deprication
  config.navigational_formats = [:json]
end
# 7 in the migration remove [versionnum] at the end of the first line
# 8 in application.rb add exposure parameter with details, so that CORS looks like this:
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins /https:\/\/\w+\.github\.io/

        resource '*', 
          :headers => :any, 
          :expose  => ['access-token', 'expiry', 'token-type', 'uid', 'client'], # <- here it goes
          :methods => [:get, :post, :put, :delete, :options]
      end
    end
