require "kemal"
require "json"
require "time"
require "../common/helpers"
require "./config"
require "./model"

module SComments
  module Controller
    def self.get_all(env)
      env.response.content_type = "application/json"
      Comment.all.to_json
    end

    def self.get_by_user(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "`uid` must be an Int.") unless uid
      paginated_entity_list(env, Comment, "user = #{uid}")
    end

    def self.get_by_post(env)
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "`pid` must be an Int.") unless pid
      paginated_entity_list(env, Comment, "post = #{pid}")
    end

    def self.get_by_user_and_post(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "`uid` must be an Int.") unless uid
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "`pid` must be an Int.") unless pid
      paginated_entity_list(env, Comment, "(user = #{uid}) and (post = #{pid})")
    end

    def self.create(env)
      attrs = env.params.json.select(Comment::CREATE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      c = Comment.new(attrs)
      c.date = Time.now.to_s
      c.rating = 0i64 unless c.rating

      panic(env, 400, c.errors[0]) unless c.valid?
      panic(env, 500, c.errors[0]) unless c.save
    end

    def self.get(env)
      c = nil
      get_requested_entity(env, Comment, c)
      env.response.content_type = "application/json"
      c.to_json
    end

    def self.delete(env)
      c = nil
      get_requested_entity(env, Comment, c)
      panic(env, 500, c.errors[0]) unless c.destroy
    end

    def self.delete_by_user(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "`uid` must be an Int.") unless uid
      filtered_delete(env, Comment, "user = #{uid}")
    end

    def self.delete_by_post(env)
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "`pid` must be an Int.") unless pid
      filtered_delete(env, Comment, "post = #{pid}")
    end
  end
end
