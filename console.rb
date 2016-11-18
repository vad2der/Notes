# in order to run the console with project environment
rails console

# to list all classes in models, even if they are not using ORMs
Dir['**/models/**/*.rb'].map {|f| File.basename(f, '.*').camelize.constantize }

# run server in current folder
ruby -run -e httpd . -p 9090
