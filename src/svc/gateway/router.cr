require "kemal"
require "./config"
require "./api_controller"
require "./oauth_controller"

module SGateway
  module Router
    # /post

    get "/posts" do |env|
      ApiController.get_all_posts(env)
    end

    get "/post/:id" do |env|
      ApiController.get_post(env)
    end

    get "/post/:id/comments" do |env|
      ApiController.get_comments_on_post(env)
    end

    post "/post" do |env|
      ApiController.create_post(env)
    end

    post "/post/:id/comment" do |env|
      ApiController.create_comment_on_post(env)
    end

    put "/post/:id" do |env|
      ApiController.update_post(env)
    end

    delete "/post/:id" do |env|
      ApiController.delete_post(env)
    end

    # /user

    get "/user/:id" do |env|
      ApiController.get_user(env)
    end

    get "/user/:id/posts" do |env|
      ApiController.get_posts_by_user(env)
    end

    get "/user/:id/comments" do |env|
      ApiController.get_comments_by_user(env)
    end

    get "/user/:id/post/:pid/comments" do |env|
      ApiController.get_comments_by_user_on_post(env)
    end

    put "/user/:id" do |env|
      ApiController.update_user(env)
    end

    # /comment

    get "/comment/:id" do |env|
      ApiController.get_comment(env)
    end

    delete "/comment/:id" do |env|
      ApiController.delete_comment(env)
    end

    # /oauth

    get "/oauth/authorize" do |env|
      OAuthController.request_code(env)
    end

    get "/oauth/autotoken" do |env|
      OAuthController.oauth_autotoken_callback(env)
    end

    get "/oauth/callback" do |env|
      OAuthController.oauth_simple_callback(env)
    end

    get "/oauth/login" do |env|
      OAuthController.oauth_login_form(env)
    end

    post "/oauth/login" do |env|
      OAuthController.oauth_login(env)
    end

    post "/oauth/token" do |env|
      OAuthController.request_token(env)
    end
  end
end
