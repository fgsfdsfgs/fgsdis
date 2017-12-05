require "kemal"
require "./config"
require "./controller"

module SUsers
  module Router
    get "/users" do |env|
      Controller.get_all(env)
    end

    post "/user" do |env|
      Controller.create(env)
    end

    get "/user/:id" do |env|
      Controller.get(env)
    end

    put "/user/:id" do |env|
      Controller.update(env)
    end

    delete "/user/:id" do |env|
      Controller.delete(env)
    end
  end
end
