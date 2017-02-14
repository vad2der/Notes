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
# 9 making test
rails g rspec:request AuthApi
# 10 update Gemfile with
gem 'database_cleaner', '~>1.5', '>=1.5.3'
gem 'factory_girl_rails', '~>4.7', '>=4.7.0'
gem 'faker', '~>1.6', '>=1.6.6'
# 11 go into spec
require 'rails_helper'

RSpec.describe "Authentication Api", type: :request do
  include_context "db_cleanup_each", :transaction
  let(:user_props) { FactoryGirl.attributes_for(:user) }

  context "sign-up" do
    context "valid registration" do
      it "successfully creates account" do
        signup user_props

        payload=parsed_body
        expect(payload).to include("status"=>"success")
        expect(payload).to include("data")
        expect(payload["data"]).to include("id")
        expect(payload["data"]).to include("provider"=>"email")
        expect(payload["data"]).to include("uid"=>user_props[:email])
        expect(payload["data"]).to include("name"=>user_props[:name])
        expect(payload["data"]).to include("email"=>user_props[:email])
        expect(payload["data"]).to include("created_at","updated_at")
      end
    end

    context "invalid registration" do
      context "missing information" do
        it "reports error with messages" do
          signup user_props.except(:email), :unprocessable_entity
          #pp parsed_body

          payload=parsed_body
          expect(payload).to include("status"=>"error")
          expect(payload).to include("data")
          expect(payload["data"]).to include("email"=>nil)
          expect(payload).to include("errors")
          expect(payload["errors"]).to include("email")
          expect(payload["errors"]).to include("full_messages")
          expect(payload["errors"]["full_messages"]).to include(/Email/i)
        end
      end

      context "non-unique information" do
        it "reports non-unique e-mail" do
          signup user_props, :ok
          signup user_props, :unprocessable_entity
          
          payload=parsed_body
          expect(payload).to include("status"=>"error")
          expect(payload).to include("errors")
          expect(payload["errors"]).to include("email")
          expect(payload["errors"]).to include("full_messages")
          expect(payload["errors"]["full_messages"]).to include(/Email/i)
        end
      end
    end
  end

  context "anonymous user" do
    it "accesses unprotected" do
      get authn_whoami_path
      #pp parsed_body
      expect(response).to have_http_status(:ok)

      expect(parsed_body).to eq({})
    end
    it "fails to access protected resource" do
      get authn_checkme_path
      #pp parsed_body
      expect(response).to have_http_status(:unauthorized)

      expect(parsed_body).to include("errors"=>["Authorized users only."])
    end
  end

  context "login" do
    let(:account) { signup user_props, :ok }
    let!(:user) { login account, :ok }

    context "valid user login" do

      it "generates access token" do
        expect(response.headers).to include("uid"=>account[:uid])
        expect(response.headers).to include("access-token")
        expect(response.headers).to include("client")
        expect(response.headers).to include("token-type"=>"Bearer")
      end
      it "extracts access headers" do
        expect(access_tokens?).to be true
        expect(access_tokens).to include("uid"=>account[:uid])
        expect(access_tokens).to include("access-token")
        expect(access_tokens).to include("client")
        expect(access_tokens).to include("token-type"=>"Bearer")
      end

      it "grants access to resource" do
        jget authn_checkme_path#, access_tokens
        #pp parsed_body
        expect(response).to have_http_status(:ok)

        payload=parsed_body
        expect(payload).to include("id"=>account[:id])
        expect(payload).to include("uid"=>account[:uid])
      end

      it "grants access to resource multiple times" do
        (1..10).each do |idx|
          #puts idx
          #sleep 6
          #quick calls < 5sec use same tokens
          jget authn_checkme_path#, access_tokens
          expect(response).to have_http_status(:ok)
        end
      end

      it "logout" do
        logout :ok
        expect(access_tokens?).to be false

        jget authn_checkme_path#, access_tokens
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "invalid password" do
      it "rejects credentials" do
        login account.merge(:password=>"badpassword"), :unauthorized
      end
    end
  end
end
# 12 Make a factory for this test
FactoryGirl.define do

  factory :user do
    name     { Faker::Name.first_name }
    email    { Faker::Internet.email }
    password { Faker::Internet.password }
  end

  factory :admin, class: User, parent: :user do
    after(:build) do |user|
      user.roles.build(:role_name=>Role::ADMIN)
    end
  end

  factory :originator, class: User, parent: :user do
    transient do
      mname nil
    end
    after(:build) do |user, props|
      user.roles.build(:role_name=>Role::ORIGINATOR, :mname=>props.mname)
    end
  end
end
# 13 allow parameters in application_controller.rb
before_action :configure_permitted_parameters, if: :devise_controller?
..
protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end
# 14 in spec/support/api_helper.rb
# add, because it will be reused maultiple times
module ApiHelper
  def parsed_body
    JSON.parse(response.body)
  end

  # automates the passing of payload bodies as json
  ["post", "put", "patch", "get", "head", "delete"].each do |http_method_name|
    define_method("j#{http_method_name}") do |path,params={},headers={}| 
      if ["post","put","patch"].include? http_method_name
        headers=headers.merge('content-type' => 'application/json') if !params.empty?
        params = params.to_json
      end
      self.send(http_method_name, 
            path, 
            params,
            headers.merge(access_tokens))
    end
  end

  def signup registration, status=:ok
    jpost user_registration_path, registration
    expect(response).to have_http_status(status)
    payload=parsed_body
    if response.ok?
      registration.merge(:id=>payload["data"]["id"],
                         :uid=>payload["data"]["uid"])
    end
  end

  def login credentials, status=:ok
    jpost user_session_path, credentials.slice(:email, :password)
    expect(response).to have_http_status(status)
    return response.ok? ? parsed_body["data"] : parsed_body
  end
  def logout status=:ok
    jdelete destroy_user_session_path
    @last_tokens={}
    expect(response).to have_http_status(status) if status
  end

  def access_tokens?
    !response.headers["access-token"].nil?  if response
  end
  def access_tokens
    if access_tokens?
      @last_tokens=["uid","client","token-type","access-token"].inject({}) {|h,k| h[k]=response.headers[k]; h}
    end
    @last_tokens || {}
  end

  def create_resource path, factory, status=:created
    jpost path, FactoryGirl.attributes_for(factory)
    expect(response).to have_http_status(status) if status
    parsed_body
  end

  def apply_admin account
    User.find(account.symbolize_keys[:id]).roles.create(:role_name=>Role::ADMIN)
    return account
  end
  def apply_originator account, model_class
    User.find(account.symbolize_keys[:id]).add_role(Role::ORIGINATOR, model_class).save
    return account
  end
  def apply_role account, role, object
    user=User.find(account.symbolize_keys[:id])
    arr=object.kind_of?(Array) ? object : [object]
    arr.each do |m|
      user.add_role(role, m).save
    end
    return account
  end
  def apply_organizer account, object
    apply_role(account,Role::ORGANIZER, object)
  end
  def apply_member account, object
    apply_role(account, Role::MEMBER, object)
  end
end

RSpec.shared_examples "resource index" do |model|
  let!(:resources) { (1..5).map {|idx| FactoryGirl.create(model) } }
  let!(:apply_roles) { apply_organizer user, resources }
  let(:payload) { parsed_body }

  it "returns all #{model} instances" do
    jget send("#{model}s_path"), {}, {"Accept"=>"application/json"}
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq("application/json")

    expect(payload.count).to eq(resources.count)
    response_check if respond_to?(:response_check)
  end
end

RSpec.shared_examples "show resource" do |model|
  let(:resource) { FactoryGirl.create(model) }
  let!(:apply_roles) { apply_organizer user, resource }
  let(:payload) { parsed_body }
  let(:bad_id) { 1234567890 }

  it "returns #{model} when using correct ID" do
    jget send("#{model}_path", resource.id)
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq("application/json")
    response_check if respond_to?(:response_check)
  end

  it "returns not found when using incorrect ID" do
    jget send("#{model}_path", bad_id)
    expect(response).to have_http_status(:not_found)
    expect(response.content_type).to eq("application/json") 

    payload=parsed_body
    expect(payload).to have_key("errors")
    expect(payload["errors"]).to have_key("full_messages")
    expect(payload["errors"]["full_messages"][0]).to include("cannot","#{bad_id}")
  end
end

RSpec.shared_examples "create resource" do |model|
  let(:resource_state) { FactoryGirl.attributes_for(model) }
  let(:payload)        { parsed_body }
  let(:resource_id)    { payload["id"] }

  it "can create valid #{model}" do
    jpost send("#{model}s_path"), resource_state
    expect(response).to have_http_status(:created)
    expect(response.content_type).to eq("application/json") 

    # verify payload has ID and delegate for addition checks
    expect(payload).to have_key("id")
    response_check if respond_to?(:response_check)

    # verify we can locate the created instance in DB
    jget send("#{model}_path", resource_id)
    expect(response).to have_http_status(:ok)
  end
end

RSpec.shared_examples "modifiable resource" do |model|
  let(:resource) do 
    jpost send("#{model}s_path"), FactoryGirl.attributes_for(model)
    expect(response).to have_http_status(:created)
    parsed_body
  end
  let(:new_state) { FactoryGirl.attributes_for(model) }

  it "can update #{model}" do
      # change to new state
      jput send("#{model}_path", resource["id"]), new_state
      expect(response).to have_http_status(:no_content)

      update_check if respond_to?(:update_check)
    end

  it "can be deleted" do
    jhead send("#{model}_path", resource["id"])
    expect(response).to have_http_status(:ok)

    jdelete send("#{model}_path", resource["id"])
    expect(response).to have_http_status(:no_content)
    
    jhead send("#{model}_path", resource["id"])
    expect(response).to have_http_status(:not_found)
  end
end

# 15 create a resource which requires a login
# create a controller with 2 actions:
rails g controller authn whoami checkme

# 16 GO INTO THIS CONTROLLER AND ALTER IT
class AuthnController < ApplicationController
  before_action :authenticate_user!, only: [:checkme]

  def whoami
    if @user=current_user
      @roles=current_user.roles.application.pluck(:role_name, :mname)
    end
  end

  def checkme
    render json: current_user || {}
  end
end

# 17 create a model with authorization params
rails-api g scaffold Image caption creator_id:integer:index --orm active_record

# 18 in migration explicitely say that creator_id can not be empty
class CreateThingImages < ActiveRecord::Migration  
  def change
    create_table :images do |t|
      t.string :caption
      t.integer :creator_id, {null:false}

      t.timestamps null: false
    end
end
