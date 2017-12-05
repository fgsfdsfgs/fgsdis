require "kemal"
require "./config"
require "./controller"

module SComments
  module Router
    get "/comments" do |env|
      Controller.get_all(env)
    end

    get "/comments/by_user/:uid" do |env|
      Controller.get_by_user(env)
    end

    get "/comments/by_post/:pid" do |env|
      Controller.get_by_post(env)
    end

    get "/comments/by_user/:uid/by_post/:pid" do |env|
      Controller.get_by_user_and_post(env)
    end

    post "/comment" do |env|
      Controller.create(env)
    end

    get "/comment/:id" do |env|
      Controller.get(env)
    end

    delete "/comment/:id" do |env|
      Controller.delete(env)
    end

    delete "/comments/by_user/:uid" do |env|
      Controller.delete_by_user(env)
    end

    delete "/comments/by_post/:pid" do |env|
      Controller.delete_by_post(env)
    end
  end
end
