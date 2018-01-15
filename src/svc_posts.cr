require "kemal"
require "./common/**"
require "./svc/posts/**"

ServiceAuth.add_creds(SPosts::CONFIG_GATEID, SPosts::CONFIG_SECRET)
EventQueue.start_event_source(
  "svc_posts",
  SPosts::CONFIG_MQ_HOST,
  SPosts::CONFIG_MQ_PORT,
  SPosts::CONFIG_MQ_USER,
  SPosts::CONFIG_MQ_PASSWORD
)

Kemal.config.port = SPosts::CONFIG_PORT
serve_static false
Kemal.run
