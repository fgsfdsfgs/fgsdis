require "kemal"
require "./common/**"
require "./svc/comments/**"

Kemal.config.port = SComments::CONFIG_PORT
serve_static false

RequestQueue.attach_to?(SComments::CONFIG_REDIS_ADDR, "comments")
Kemal.run
