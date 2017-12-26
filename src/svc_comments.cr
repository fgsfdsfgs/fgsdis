require "kemal"
require "./common/**"
require "./svc/comments/**"

Kemal.config.port = SComments::CONFIG_PORT
serve_static false
Kemal.run
