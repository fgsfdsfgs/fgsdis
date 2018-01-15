require "kemal"
require "./common/**"
require "./svc/users/**"

ServiceAuth.add_creds(SUsers::CONFIG_GATEID, SUsers::CONFIG_SECRET)
EventQueue.start_event_source(
  "svc_users",
  SUsers::CONFIG_MQ_HOST,
  SUsers::CONFIG_MQ_PORT,
  SUsers::CONFIG_MQ_USER,
  SUsers::CONFIG_MQ_PASSWORD
)

Kemal.config.port = SUsers::CONFIG_PORT
serve_static false
Kemal.run
