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
