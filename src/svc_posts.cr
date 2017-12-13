require "kemal"
require "./common/**"
require "./svc/posts/**"

Kemal.config.port = SPosts::CONFIG_PORT
serve_static false

unless ENV["KEMAL_ENV"]? == "test"
  RequestQueue.attach_to(SPosts::CONFIG_REDIS_ADDR, "posts")
end
Kemal.run
