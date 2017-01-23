# in order to run the console with project environment
rails console

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
