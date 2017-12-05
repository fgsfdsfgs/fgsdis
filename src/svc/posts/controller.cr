require "kemal"
require "json"
require "time"
require "../common/helpers"
require "./config"
require "./model"

module SPosts
  module Controller
    def self.get_all(env)
      paginated_entity_list(env, Post)
    end

    def self.get_by_user(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "`uid` must be an Int.") unless uid
      paginated_entity_list(env, Post, "user = #{uid}")
    end

    def self.create(env)
      attrs = env.params.json.select(Post::SETTABLE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      p = Post.new(attrs)
      p.date = Time.now.to_s

      panic(env, 400, p.errors[0]) unless p.valid?
      panic(env, 500, p.errors[0]) unless p.save
    end

    def self.get(env)
      p = nil
      get_requested_entity(env, Post, p)
      env.response.content_type = "application/json"
      p.to_json
    end

    def self.update(env)
      p = nil
      get_requested_entity(env, Post, p)
      attrs = env.params.json.select(Post::SETTABLE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?
      p.set_attributes(attrs)
      panic(env, 400, p.errors[0]) unless p.valid?
      panic(env, 500, p.errors[0]) unless p.save
    end

    def self.delete(env)
      p = nil
      get_requested_entity(env, Post, p)
      panic(env, 500, p.errors[0]) unless p.destroy
    end

    def self.delete_by_user(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "`uid` must be an Int.") unless uid
      filtered_delete(env, Post, "user = #{uid}")
    end
  end
end
