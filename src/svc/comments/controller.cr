require "kemal"
require "json"
require "time"
require "html"
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
      panic(env, 400, "User ID must be an Int.") unless uid
      paginated_entity_list(env, Comment, "user = #{uid}")
    end

    def self.get_by_post(env)
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "Post ID must be an Int.") unless pid
      paginated_entity_list(env, Comment, "post = #{pid}")
    end

    def self.get_by_user_and_post(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "User ID must be an Int.") unless uid
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "Post ID must be an Int.") unless pid
      paginated_entity_list(env, Comment, "(user = #{uid}) and (post = #{pid})")
    end

    def self.create(env)
      attrs = env.params.json.select(Comment::CREATE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      tidy_fields(attrs)

      c = Comment.new(attrs)
      c.date = Time.now.to_s("%FT%X")
      c.rating = 0i64 unless c.rating

      panic(env, 400, c.errors[0]) unless c.valid?
      if c.rating != 0
        comments = Comment.all("WHERE user=#{c.user} AND post=#{c.post} AND rating != 0")
        panic(env, 400, "You have already rated this post.") if !comments.empty?
      end
      panic(env, 500, c.errors[0]) unless c.save

      created(env, "/comment/#{c.id}")
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
      panic(env, 400, "User ID must be an Int.") unless uid
      filtered_delete(env, Comment, "user = #{uid}")
    end

    def self.delete_by_post(env)
      pid = env.params.url.fetch("pid", "").to_i64?
      panic(env, 400, "Post ID must be an Int.") unless pid
      filtered_delete(env, Comment, "post = #{pid}")
    end
  end
end
