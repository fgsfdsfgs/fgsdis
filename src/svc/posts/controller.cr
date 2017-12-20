require "kemal"
require "json"
require "time"
require "html"
require "../common/helpers"
require "./config"
require "./model"

module SPosts
  module Controller
    def self.get_all(env)
      paginated_entity_list(env, Post, "", true)
    end

    def self.get_by_user(env)
      uid = env.params.url.fetch("uid", "").to_i64?
      panic(env, 400, "User ID must be an Int.") unless uid
      paginated_entity_list(env, Post, "user = #{uid}", true)
    end

    def self.create(env)
      attrs = env.params.json.select(Post::CREATE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      tidy_fields(attrs)

      p = Post.new(attrs)
      p.date = Time.now.to_s("%FT%X")
      p.rating = 0i64

      panic(env, 400, p.errors[0]) unless p.valid?
      panic(env, 500, p.errors[0]) unless p.save

      created(env, "/post/#{p.id}")
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
      attrs = env.params.json.select(Post::EDIT_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?
      tidy_fields(attrs)
      p.set_attributes(attrs)
      panic(env, 400, p.errors[0]) unless p.valid?
      panic(env, 500, p.errors[0]) unless p.save
    end

    def self.patch(env)
      p = nil
      get_requested_entity(env, Post, p)
      diff = env.params.json["rating"]?
      panic(env, 400, "No relevant fields in JSON.") unless diff
      diff = diff.to_s.to_i64?
      panic(env, 400, "`rating` must be an Int.") unless diff
      panic(env, 400, "`rating` must be 0, -1 or 1.") if diff > 1 || diff < -1
      if rating = p.rating
        p.rating = rating + diff
      end
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
      panic(env, 400, "User ID must be an Int.") unless uid
      filtered_delete(env, Post, "user = #{uid}")
    end
  end
end
