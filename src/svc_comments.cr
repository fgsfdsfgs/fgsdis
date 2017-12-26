require "kemal"
require "./common/**"
require "./svc/comments/**"

ServiceAuth.set_creds(SComments::CONFIG_GATEID, SComments::CONFIG_SECRET)

Kemal.config.port = SComments::CONFIG_PORT
serve_static false
Kemal.run
