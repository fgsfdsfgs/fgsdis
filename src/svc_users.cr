require "kemal"
require "./common/**"
require "./svc/users/**"

Kemal.config.port = SUsers::CONFIG_PORT
serve_static false
Kemal.run
