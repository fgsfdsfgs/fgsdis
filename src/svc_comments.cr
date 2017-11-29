require "kemal"
require "./common/**"
require "./svc/comments/**"

Kemal.config.port = CONFIG_PORT
serve_static false
Kemal.run
