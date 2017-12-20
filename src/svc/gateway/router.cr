require "kemal"
require "./config"
require "./controller"

module SGateway
  module Router
    # /post

    get "/posts" do |env|
      Controller.get_all_posts(env)
    end

    get "/post/:id" do |env|
      Controller.get_post(env)
    end

    get "/post/:id/comments" do |env|
      Controller.get_comments_on_post(env)
    end

    post "/post" do |env|
      Controller.create_post(env)
    end

    post "/post/:id/comment" do |env|
      Controller.create_comment_on_post(env)
    end

    put "/post/:id" do |env|
      Controller.update_post(env)
    end

    delete "/post/:id" do |env|
      Controller.delete_post(env)
    end

    # /user

    get "/user/:id" do |env|
      Controller.get_user(env)
    end

    get "/user/:id/posts" do |env|
      Controller.get_posts_by_user(env)
    end

    get "/user/:id/comments" do |env|
      Controller.get_comments_by_user(env)
    end

    get "/user/:id/post/:pid/comments" do |env|
      Controller.get_comments_by_user_on_post(env)
    end

    put "/user/:id" do |env|
      Controller.update_user(env)
    end

    # /comment

    get "/comment/:id" do |env|
      Controller.get_comment(env)
    end

    delete "/comment/:id" do |env|
      Controller.delete_comment(env)
    end
  end
end
