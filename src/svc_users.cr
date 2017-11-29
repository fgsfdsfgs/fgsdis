require "kemal"
require "./common/**"
require "./svc/users/**"

Kemal.config.port = CONFIG_PORT
serve_static false
Kemal.run
