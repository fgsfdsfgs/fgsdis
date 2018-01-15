require "kemal"
require "./config"
require "./controller"

module SStats
  module Router
    get "/stats/events" do |env|
      Controller.get_all(env)
    end

    get "/stats/event/:id" do |env|
      Controller.get(env)
    end

    get "/stats/:service/events" do |env|
      Controller.get_filtered(env)
    end

    post "/stats/:service/event" do |env|
      Controller.create(env)
    end
  end
end
