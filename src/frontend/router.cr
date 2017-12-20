require "kemal"
require "json"
require "./config"
require "./utils"

module SFrontend
  get "/" do |env|
    page = env.params.query.fetch("page", "1").to_i64?
    page = 1 if !page
    r, posts = api_get_json("/posts/?#{env.params.query}")
    env.response.status_code = r.status_code
    render_view("postlist") if posts
  end

  post "/post/new" do |env|
    body = env.params.body.to_h.to_json
    r = api_post("/post", body)
    if r.status_code < 400
      env.redirect(r.headers.fetch("Location", "/"))
    else
      render_error(env, r)
    end
  end

  get "/post/new" do |env|
    render_view("newpost")
  end

  get "/post/:id" do |env|
    pid = env.params.url["id"]
    r, npost = api_get_json("/post/#{pid}")
    env.response.status_code = r.status_code
    if r.status_code < 400
      rc, comments = api_get_json("/post/#{pid}/comments")
      comments = JSON::Any.new([] of JSON::Type) unless comments
      post = npost.not_nil!
      render_view("postview")
    else
      render_error(env, r)
    end
  end

  get "/post/:id/edit" do |env|
    pid = env.params.url["id"]
    r, npost = api_get_json("/post/#{pid}")
    if r.status_code < 400
      post = npost.not_nil!
      render_view("editpost")
    else
      render_error(env, r)
    end
  end

  post "/post/:id/edit" do |env|
    pid = env.params.url["id"]
    body = env.params.body.to_h.to_json
    r = api_put("/post/#{pid}", body)
    if r.status_code < 400
      env.redirect("/post/#{pid}")
    else
      render_error(env, r)
    end
  end

  post "/post/:id/comment" do |env|
    pid = env.params.url["id"]
    body = env.params.body.to_h.to_json
    r = api_post("/post/#{pid}/comment", body)
    if r.status_code < 400
      env.redirect("/post/#{pid}")
    else
      render_error(env, r)
    end
  end

  post "/post/:id/delete" do |env|
    pid = env.params.url["id"]
    r = api_delete("/post/#{pid}")
    if r.status_code < 400
      env.redirect("/")
    else
      render_error(env, r)
    end
  end

  get "/user/:id" do |env|
    uid = env.params.url["id"]
    r, nuser = api_get_json("/user/#{uid}")
    if r.status_code < 400
      user = nuser.not_nil!
      cpage = env.params.query.fetch("cpage", "1").to_i64?
      cpage = 1 if !cpage
      ppage = env.params.query.fetch("ppage", "1").to_i64?
      ppage = 1 if !ppage
      goto = env.params.query.fetch("goto", "posts").to_s
      rp, uposts = api_get_json("/user/#{uid}/posts?page=#{ppage}")
      rc, ucomments = api_get_json("/user/#{uid}/comments?page=#{cpage}")
      render_view("userview")
    else
      render_error(env, r)
    end
  end

  get "/user/:id/edit" do |env|
    uid = env.params.url["id"]
    r, nuser = api_get_json("/user/#{uid}")
    if r.status_code < 400
      user = nuser.not_nil!
      render_view("edituser")
    else
      render_error(env, r)
    end
  end

  post "/user/:id/edit" do |env|
    uid = env.params.url["id"]
    body = env.params.body.to_h.to_json
    r = api_put("/user/#{uid}", body)
    if r.status_code < 400
      env.redirect("/user/#{uid}")
    else
      render_error(env, r)
    end
  end

  get "/comment/:id" do |env|
    cid = env.params.url["id"]
    r, ncomment = api_get_json("/comment/#{cid}")
    env.response.status_code = r.status_code
    if r.status_code < 400
      comment = ncomment.not_nil!
      render_view("commentview")
    else
      render_error(env, r)
    end
  end

  post "/comment/:id/delete" do |env|
    cid = env.params.url["id"]
    r = api_delete("/comment/#{cid}")
    transform_response(env, r)
    if r.status_code < 400
      env.redirect("/")
    else
      render_error(env, r)
    end
  end
end
