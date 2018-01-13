require "kemal"
require "json"
require "html"
require "uri"
require "./config"
require "./utils"
require "./auth"

module SFrontend
  get "/" do |env|
    page = env.params.query.fetch("page", "1").to_i64?
    page = 1 if !page
    size = env.params.query.fetch("size", "5").to_i64?
    size = 5 if !size
    r, posts = api_get_json(env, "/posts/?size=#{size}&page=#{page}")
    if posts && r.status_code < 400
      render_view("postlist")
    else
      render_error(env, r)
    end
  end

  post "/post/new" do |env|
    body = env.params.body.to_h.to_json
    r = api_post(env, "/post", body)
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
    r, npost = api_get_json(env, "/post/#{pid}")
    if r.status_code < 400
      rc, comments = api_get_json(env, "/post/#{pid}/comments")
      comments = JSON::Any.new([] of JSON::Type) unless comments
      post = npost.not_nil!
      render_view("postview")
    else
      render_error(env, r)
    end
  end

  get "/post/:id/edit" do |env|
    pid = env.params.url["id"]
    r, npost = api_get_json(env, "/post/#{pid}")
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
    r = api_put(env, "/post/#{pid}", body)
    if r.status_code < 400
      env.redirect("/post/#{pid}")
    else
      render_error(env, r)
    end
  end

  post "/post/:id/comment" do |env|
    pid = env.params.url["id"]
    body = env.params.body.to_h.to_json
    r = api_post(env, "/post/#{pid}/comment", body)
    if r.status_code < 400
      env.redirect("/post/#{pid}")
    else
      render_error(env, r)
    end
  end

  post "/post/:id/delete" do |env|
    pid = env.params.url["id"]
    r = api_delete(env, "/post/#{pid}")
    if r.status_code < 400
      env.redirect("/")
    else
      render_error(env, r)
    end
  end

  get "/user/:id" do |env|
    uid = env.params.url["id"]
    r, nuser = api_get_json(env, "/user/#{uid}")
    if r.status_code < 400
      user = nuser.not_nil!
      cpage = env.params.query.fetch("cpage", "1").to_i64?
      cpage = 1 if !cpage
      ppage = env.params.query.fetch("ppage", "1").to_i64?
      ppage = 1 if !ppage
      size = env.params.query.fetch("size", "10").to_i64?
      size = 10 if !size
      goto = env.params.query.fetch("goto", "posts").to_s
      rp, uposts = api_get_json(env, "/user/#{uid}/posts?page=#{ppage}&size=#{size}")
      rc, ucomments = api_get_json(env, "/user/#{uid}/comments?page=#{cpage}&size=#{size}")
      render_view("userview")
    else
      render_error(env, r)
    end
  end

  get "/user/:id/edit" do |env|
    uid = env.params.url["id"]
    r, nuser = api_get_json(env, "/user/#{uid}")
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
    r = api_put(env, "/user/#{uid}", body)
    if r.status_code < 400
      env.redirect("/user/#{uid}")
    else
      render_error(env, r)
    end
  end

  get "/comment/:id" do |env|
    cid = env.params.url["id"]
    r, ncomment = api_get_json(env, "/comment/#{cid}")
    if r.status_code < 400
      comment = ncomment.not_nil!
      render_view("commentview")
    else
      render_error(env, r)
    end
  end

  post "/comment/:id/delete" do |env|
    cid = env.params.url["id"]
    r = api_delete(env, "/comment/#{cid}")
    transform_response(env, r)
    if r.status_code < 400
      env.redirect("/")
    else
      render_error(env, r)
    end
  end

  get "/login" do |env|
    error = env.params.query.fetch("error", "")
    render_view("loginview")
  end

  post "/login" do |env|
    user = URI.escape(env.params.body.fetch("username", ""))
    pass = URI.escape(env.params.body.fetch("password", ""))

    body = "grant_type=password&username=#{user}&password=#{pass}" \
           "&client_id=#{CONFIG_OAUTH_APPID}&client_secret=#{CONFIG_OAUTH_SECRET}"

    r = api_post(env, "/oauth/token", body, "application/x-www-form-urlencoded")

    next render_error(env, r) if r.status_code >= 400
    token = parse_json?(r.body)
    next render_error(env, r) unless token

    access = token["access_token"].as_s
    refresh = token["refresh_token"].as_s
    exp = token["expires_in"].as_s.to_i64

    exptime = Time.now + 24.hours

    env.response.cookies <<
      HTTP::Cookie.new("access_token", access, expires: exptime)
    env.response.cookies <<
      HTTP::Cookie.new("refresh_token", refresh, expires: exptime)

    uid = token["user_id"]?.to_s

    r, user = api_get_json(env, "/user/#{uid}")
    if r.status_code < 400
      uname = user.not_nil!["name"]?.to_s
      env.response.cookies <<
        HTTP::Cookie.new("user_id", uid, expires: exptime)
      env.response.cookies <<
        HTTP::Cookie.new("user_name", uname, expires: exptime)
    end

    env.redirect("/")
  end

  get "/logout" do |env|
    invalidate_auth_cookies(env)
    env.redirect("/")
  end
end
