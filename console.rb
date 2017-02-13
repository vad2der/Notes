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
