require "kemal"
require "json"
require "time"
require "../common/helpers"
require "./config"
require "./model"

module SComments
  get "/comments" do |env|
    paginated_entity_list(env, Comment)
  end

  get "/comments/by_user/:uid" do |env|
    uid = env.params.url.fetch("uid", "").to_i64?
    panic(env, 400, "`uid` must be an Int.") unless uid
    paginated_entity_list(env, Comment, "user = #{uid}")
  end

  get "/comments/by_post/:pid" do |env|
    pid = env.params.url.fetch("pid", "").to_i64?
    panic(env, 400, "`pid` must be an Int.") unless pid
    paginated_entity_list(env, Comment, "post = #{pid}")
  end

  get "/comments/by_user/:uid/by_post/:pid" do |env|
    uid = env.params.url.fetch("uid", "").to_i64?
    panic(env, 400, "`uid` must be an Int.") unless uid
    pid = env.params.url.fetch("pid", "").to_i64?
    panic(env, 400, "`pid` must be an Int.") unless pid
    paginated_entity_list(env, Comment, "(user = #{uid}) and (post = #{pid})")
  end

  post "/comment" do |env|
    attrs = env.params.json.select(Comment::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

    c = Comment.new(attrs)
    c.date = Time.now.to_s

    panic(env, 400, c.errors[0]) unless c.valid?
    panic(env, 500, c.errors[0]) unless c.save
  end

  get "/comment/:id" do |env|
    c = nil
    get_requested_entity(env, Comment, c)
    env.response.content_type = "application/json"
    c.to_json
  end

  put "/comment/:id" do |env|
    c = nil
    get_requested_entity(env, Comment, c)
    attrs = env.params.json.select(Comment::SETTABLE_FIELDS)
    panic(env, 400, "No relevant fields in JSON.") if attrs.empty?
    c.set_attributes(attrs)
    panic(env, 400, c.errors[0]) unless c.valid?
    panic(env, 500, c.errors[0]) unless c.save
  end

  delete "/comment/:id" do |env|
    c = nil
    get_requested_entity(env, Comment, c)
    panic(env, 500, c.errors[0]) unless c.destroy
  end

  delete "/comments/by_user/:uid" do |env|
    uid = env.params.url.fetch("uid", "").to_i64?
    panic(env, 400, "`uid` must be an Int.") unless uid
    filtered_delete(env, Comment, "user = #{uid}")
  end

  delete "/comments/by_post/:pid" do |env|
    pid = env.params.url.fetch("pid", "").to_i64?
    panic(env, 400, "`pid` must be an Int.") unless pid
    filtered_delete(env, Comment, "post = #{pid}")
  end
end
