require "kemal"
require "./svc/gateway/**"

Kemal.config.port = CONFIG_PORT
serve_static false
Kemal.run
