require "kemal"
require "json"
require "time"
require "../../common/helpers"
require "./config"
require "./user_model"

module SUsers
  module UserController
    def self.get_all(env)
      env.response.content_type = "application/json"
      return User.all.to_json
    end

    def self.create(env)
      attrs = env.params.json.select(User::CREATE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      tidy_fields(attrs)

      u = User.new(attrs)
      u.reg_date = Time.now.to_s("%FT%X")
      u.password = u.password ? sha256(u.password.to_s) : nil
      u.role = "user"

      panic(env, 400, u.errors[0]) unless u.valid?
      panic(env, 500, u.errors[0]) unless u.save

      created(env, "/user/#{u.id}")
    end

    def self.get(env)
      u = nil
      get_requested_entity(env, User, u)
      env.response.content_type = "application/json"
      return u.to_json
    end

    def self.update(env)
      u = nil
      get_requested_entity(env, User, u)
      attrs = env.params.json.select(User::EDIT_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      tidy_fields(attrs)

      u.set_attributes(attrs)
      panic(env, 400, u.errors[0]) unless u.valid?
      panic(env, 500, u.errors[0]) unless u.save
    end

    def self.delete(env)
      u = nil
      get_requested_entity(env, User, u)
      panic(env, 500, u.errors[0]) unless u.destroy
    end
  end
end
