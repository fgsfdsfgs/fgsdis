require "http"
require "html"
require "time"
require "kemal"
require "./utils"

def invalidate_auth_cookies(env)
  old = Time.epoch(0)
  env.response.cookies <<
    HTTP::Cookie.new("access_token", "", expires: old)
  env.response.cookies <<
    HTTP::Cookie.new("refresh_token", "", expires: old)
  env.response.cookies <<
    HTTP::Cookie.new("access_level", "", expires: old)
  env.response.cookies <<
    HTTP::Cookie.new("user_id", "", expires: old)
  env.response.cookies <<
    HTTP::Cookie.new("user_name", "", expires: old)
end

macro redirect_to_login_and_halt(env)
  invalidate_auth_cookies({{env}})
  {{env}}.redirect("/login")
  {{env}}.response.close
  next
end

def refresh_auth_token(env)
  cr = env.request.cookies["refresh_token"]?
  refresh = cr ? cr.value : ""
  return nil if refresh == ""
  nil
end

def get_auth_headers(env)
  hdr = HTTP::Headers.new

  if ct = env.request.cookies["access_token"]?
    hdr["Authorization"] = "Bearer " + ct.value
  end

  hdr
end
