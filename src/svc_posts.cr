require "kemal"
require "./common/**"
require "./svc/posts/**"

Kemal.config.port = SPosts::CONFIG_PORT
serve_static false
Kemal.run
