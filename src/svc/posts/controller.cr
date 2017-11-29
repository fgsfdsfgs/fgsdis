require "kemal"
require "json"
require "time"
require "../common/helpers"
require "./config"
require "./model"

module SPosts
  get "/posts" do |env|
    paginated_entity_list(env, Post)
  end

  get "/posts/by_user/:uid" do |env|
    uid = env.params.url.fetch("uid", "").to_i64?
    panic(env, 400, "`uid` must be an Int.") unless uid
    paginated_entity_list(env, Post, "user = #{uid}")
  end

  post "/post" do |env|
    attrs = env.params.json.select(Post::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

    p = Post.new(attrs)
    p.date = Time.now.to_s

    panic(env, 400, p.errors[0]) unless p.valid?
    panic(env, 500, p.errors[0]) unless p.save
  end

  get "/post/:id" do |env|
    p = nil
    get_requested_entity(env, Post, p)
    env.response.content_type = "application/json"
    p.to_json
  end

  put "/post/:id" do |env|
    p = nil
    get_requested_entity(env, Post, p)
    attrs = env.params.json.select(Post::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?
    p.set_attributes(attrs)
    panic(env, 400, p.errors[0]) unless p.valid?
    panic(env, 500, p.errors[0]) unless p.save
  end

  delete "/post/:id" do |env|
    p = nil
    get_requested_entity(env, Post, p)
    panic(env, 500, p.errors[0]) unless p.destroy
  end
end
