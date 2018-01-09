require "kemal"
require "./config"
require "./user_controller"
require "./oauth_controller"

module SUsers
  module Router
    get "/users" do |env|
      UserController.get_all(env)
    end

    post "/user" do |env|
      UserController.create(env)
    end

    get "/user/:id" do |env|
      UserController.get(env)
    end

    put "/user/:id" do |env|
      UserController.update(env)
    end

    delete "/user/:id" do |env|
      UserController.delete(env)
    end

    get "/oauth/authorize" do |env|
      OAuthController.request_code(env)
    end

    post "/oauth/token" do |env|
      OAuthController.request_token(env)
    end

    post "/oauth/introspect" do |env|
      OAuthController.introspect(env)
    end
  end
end
