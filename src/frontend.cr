require "kemal"
require "./frontend/**"

Kemal.config.port = CONFIG_PORT
public_folder("./static")
Kemal.run
