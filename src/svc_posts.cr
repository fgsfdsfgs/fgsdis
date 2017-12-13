require "kemal"
require "./common/**"
require "./svc/posts/**"

Kemal.config.port = SPosts::CONFIG_PORT
serve_static false

RequestQueue.attach_to?(SPosts::CONFIG_REDIS_ADDR, "posts")
Kemal.run
