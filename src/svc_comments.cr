require "kemal"
require "./common/**"
require "./svc/comments/**"

Kemal.config.port = SComments::CONFIG_PORT
serve_static false

unless ENV["KEMAL_ENV"]? == "test"
  RequestQueue.attach_to(SComments::CONFIG_REDIS_ADDR, "comments")
end
Kemal.run
