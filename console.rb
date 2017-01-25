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

# MongoDB
# 1 add "gem 'mongoid', '~>5.1', '>=5.1.5'" to the Gemfile
# 2 create config/mongoid.yml file
rails g mongoid:config
# 3 go into config/mongoid.yml and update host from just 
#"- localhost:27017" into "- <%= ENV['MONGO_HOST'] ||= "localhost:27017" %>"
# 4 add an entr for the production mode
#production:
#    clients:
#        default:
#            uri: <%= ENV['MLAB_URI'] %> # do not forget to define
#            options:
#                connect_timeout: 15
# 5 make sure that config/application.rb has 
module Myapp
  class Application < Rails::Application
    #..
    Mongoid.load!('./config/mongoid.yml')
    #..
  end
end
# 6 comment/uncomment one of 
  # config.generators {|g| g.orm :active_record}
  # config.generators {|g| g.orm :mongoid}
# to define default orm in config/application.rb
# 7 create model+controller+view
rails g scaffold Bar name --orm mongoid --no-request-specs --no-routing-specs --no-controller-specs 
# 8 put rout in proper place
Rails.application.routes.draw do  
  scope :api, defaults: {format: :json} do    
    resources :bars, except: [:new, :edit]
  end  
end
# 9 update test specs in spec/request/api_development_spec.rb
require 'rails_helper'
RSpec.describe "ApiDevelopments", type: :request do
  def parsed_body
    JSON.parse(response.body)
  end
  	describe "MongoDB-backed" do
	    before(:each) {Bar.delete_all}
  		after(:each) {Bar.delete_all}
	    it "create MongoDB-backed model" do
	    	object = Bar.create(name: "test")
	    	expect(Bar.find(object.id).name).to eq("test")
	    end
	    it "expose MongoDB-backed API resource" do
			object = Bar.create(name: "test")
			expect(foos_path).to eq("/api/foos")
			get foo_path(object.id)
			expect(response).to have_http_status(:ok)
			expect(parsed_body["name"]).to eq("test")
      expect(parsed_body).to include("created_at")
      expect(parsed_body).to include("id"=>object.id.to_s)
		end
	end
end
end
# 10 include include Mongoid::Timestamp
class Bar
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
end
# 11 update marchalling through the output in views/bars/_bar.json.jbuilder
json.id bar.id.to_s # getting rid of hashes
json.name bar.name
json.created_at bar.created_at
json.updated_at bar.updated_at
json.url bar_url(bar, format: :json)

#CORS
# 1 add gem 'rack-cors', '~>0.4', '>=0.4.0', :require=> 'rack/cors' to Gemfile
# 2 in config/application.rb add
config.middleware.insert_before 0, "Rack::Cors" do
  allow do
     origins /https:\/\/\w+\.github\.io/
     resource '/api/*', 
      :headers => :any, 
      :methods => [:get, :post, :put, :delete, :options]
  end
end

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

