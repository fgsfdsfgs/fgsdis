require "kemal"
require "json"
require "time"
require "../common/helpers"
require "./config"
require "./model"

module SUsers
  get "/users" do |env|
    env.response.content_type = "application/json"
    User.all.to_json
  end

  post "/user" do |env|
    attrs = env.params.json.select(User::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

    u = User.new(attrs)
    u.reg_date = Time.now.to_s

    panic(env, 400, u.errors[0]) unless u.valid?
    panic(env, 500, u.errors[0]) unless u.save
  end

  get "/user/:id" do |env|
    u = nil
    get_requested_entity(env, User, u)
    env.response.content_type = "application/json"
    u.to_json
  end

  put "/user/:id" do |env|
    u = nil
    get_requested_entity(env, User, u)
    attrs = env.params.json.select(User::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?
    u.set_attributes(attrs)
    panic(env, 400, u.errors[0]) unless u.valid?
    panic(env, 500, u.errors[0]) unless u.save
  end

  delete "/user/:id" do |env|
    u = nil
    get_requested_entity(env, User, u)
    panic(env, 500, u.errors[0]) unless u.destroy
  end
end
