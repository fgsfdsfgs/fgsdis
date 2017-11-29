require "json"
require "time"
require "../common/helpers"
require "../common/utils"
require "./config"
require "./client"
require "kemal"

module SGateway
  # /post

  get "/posts" do |env|
    pass_request(env, :posts)
  end

  get "/post/:id" do |env|
    pid = env.params.url["id"]

    res, post = svc_get_entity(:posts, "/post/#{pid}")
    transform_response_and_halt(env, res) unless post

    res_u, user = svc_get_entity(:users, "/user/#{post["user"]}")
    transform_response_and_halt(env, res) unless user

    post["username"] = user["name"]
    new_body = post.to_json
    return_modified_body(env, res, new_body)
  end

  get "/post/:id/comments" do |env|
    pid = env.params.url["id"]
    request = "/comments/by_post/#{pid}"
    copy_pagination_params(env, request)
    res = svc(:comments, "GET", request)
    transform_response(env, res)
  end

  post "/post" do |env|
    pass_request(env, :posts)
  end

  post "/post/:id/comment" do |env|
    if !env.params.json.has_key?("post")
      env.params.json["post"] = env.params.url["id"]
    end
    body = env.params.json.to_json
    res = svc(:comments, "POST", "/comment", body)
    transform_response(env, res)
  end

  put "/post/:id" do |env|
    pass_request(env, :posts)
  end

  delete "/post/:id" do |env|
    pid = env.params.url["id"]
    res_comments = svc(:comments, "DELETE", "/comments/by_post/#{pid}")
    pass_request(env, :posts)
  end

  # /user

  get "/user/:id" do |env|
    pass_request(env, :users)
  end

  get "/user/:id/posts" do |env|
    uid = env.params.url["id"]
    request = "/posts/by_user/#{uid}"
    copy_pagination_params(env, request)
    res = svc(:posts, "GET", request)
    transform_response(env, res)
  end

  get "/user/:id/comments" do |env|
    uid = env.params.url["id"]
    request = "/comments/by_user/#{uid}"
    copy_pagination_params(env, request)
    res = svc(:comments, "GET", request)
    transform_response(env, res)
  end

  get "/user/:id/post/:pid/comments" do |env|
    uid = env.params.url["id"]
    pid = env.params.url["pid"]
    res = svc(:comments, "GET", "/comments/by_user/#{uid}/by_post/#{pid}")
    transform_response(env, res)
  end

  put "/user/:id" do |env|
    pass_request(env, :users)
  end

  delete "/user/:id" do |env|
    uid = env.params.url["id"]
    res_comments = svc(:comments, "DELETE", "/comments/by_user/#{uid}")
    res_posts = svc(:comments, "DELETE", "/posts/by_user/#{uid}")
    pass_request(env, :users)
  end

  # /comment

  get "/comment/:id" do |env|
    cid = env.params.url["id"]

    res, com = svc_get_entity(:comments, "/comment/#{cid}")
    transform_response_and_halt(env, res) unless com

    res_u, user = svc_get_entity(:users, "/user/#{com["user"]}")
    transform_response_and_halt(env, res) unless user

    res_p, post = svc_get_entity(:posts, "/post/#{com["post"]}")
    transform_response_and_halt(env, res) unless post

    com["username"] = user["name"]
    com["posttitle"] = post["title"]
    new_body = com.to_json
    return_modified_body(env, res, new_body)
  end

  delete "/comment/:id" do |env|
    pass_request(env, :comments)
  end

  # misc

  get "/" do |env|
    render_view "root"
  end
end
