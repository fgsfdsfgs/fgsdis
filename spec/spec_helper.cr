require "spec"
require "http"
require "json"
require "spec-kemal"
require "kemal"
require "../src/common/**"

def post_json(uri, body)
  headers = HTTP::Headers.new
  headers["Content-Type"] = "application/json"
  post uri, headers, body
end

def put_json(uri, body)
  headers = HTTP::Headers.new
  headers["Content-Type"] = "application/json"
  put uri, headers, body
end

def patch_json(uri, body)
  headers = HTTP::Headers.new
  headers["Content-Type"] = "application/json"
  patch uri, headers, body
end
