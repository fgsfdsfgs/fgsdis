require "kemal"
require "./svc/gateway/**"

Kemal.config.port = CONFIG_PORT
public_folder("./static")
Kemal.run
