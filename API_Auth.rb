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
