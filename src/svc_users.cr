require "kemal"
require "./common/**"
require "./svc/users/**"

ServiceAuth.add_creds(SUsers::CONFIG_GATEID, SUsers::CONFIG_SECRET)
ServiceAuth.add_creds("debug", "debug")

Kemal.config.port = SUsers::CONFIG_PORT
serve_static false
Kemal.run
