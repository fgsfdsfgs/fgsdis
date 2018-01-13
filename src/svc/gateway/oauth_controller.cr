require "json"
require "time"
require "../../common/helpers"
require "../../common/utils"
require "./config"
require "./client"
require "./helpers"
require "./auth"
require "./request_queue"
require "kemal"

module SGateway
  module OAuthController
    # /oauth/*

    def self.request_code(env)
      pass_request(env, :users)
    end

    def self.request_token(env)
      pass_form(env, :users)
    end

    def self.oauth_login_form(env)
      client_name = env.params.query.fetch("client_id", "[unknown]")
      render("src/views/gateloginview.ecr", "src/views/layouts/default.ecr")
    end

    def self.oauth_login(env)
      pass_form_body(env, :users, "/oauth/authorize/?#{env.params.query}")
    end

    # test callbacks

    def self.oauth_autotoken_callback(env)
      code = env.params.query["code"]?
      panic(env, 400, "`code` is required.") unless code

      body = "grant_type=authorization_code&code=#{code}&" \
             "client_id=test&client_secret=apisecret"
      ct = "application/x-www-form-urlencoded"
      res = Client.request(:users, "POST", "/oauth/token", body, ct)

      transform_response(env, res)
    end

    def self.oauth_simple_callback(env)
      code = env.params.query["code"]?
      panic(env, 400, "`code` is required.") unless code

      "<h1>This is a test OAuth2 callback page.</h1>" \
      "Congratulations, you have received an OAuth2 Code.<br/>" \
      "Your code is: <b>#{code}</b><br/>" \
      "You can now request a token using `POST /oauth/token`."
    end
  end
end
