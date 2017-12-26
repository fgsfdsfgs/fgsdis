require "kemal"
require "./common/**"
require "./svc/users/**"

ServiceAuth.set_creds(SUsers::CONFIG_GATEID, SUsers::CONFIG_SECRET)

Kemal.config.port = SUsers::CONFIG_PORT
serve_static false
Kemal.run
