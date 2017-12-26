require "kemal"
require "./common/**"
require "./svc/posts/**"

ServiceAuth.set_creds(SPosts::CONFIG_GATEID, SPosts::CONFIG_SECRET)

Kemal.config.port = SPosts::CONFIG_PORT
serve_static false
Kemal.run
