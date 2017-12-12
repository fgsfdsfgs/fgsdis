require "kemal"
require "./config"
require "./controller"

module SPosts
  module Router
    get "/posts" do |env|
      Controller.get_all(env)
    end

    get "/posts/by_user/:uid" do |env|
      Controller.get_by_user(env)
    end

    post "/post" do |env|
      Controller.create(env)
    end

    get "/post/:id" do |env|
      Controller.get(env)
    end

    put "/post/:id" do |env|
      Controller.update(env)
    end

    patch "/post/:id" do |env|
      Controller.patch(env)
    end

    delete "/post/:id" do |env|
      Controller.delete(env)
    end

    delete "/posts/by_user/:uid" do |env|
      Controller.delete_by_user(env)
    end
  end
end
