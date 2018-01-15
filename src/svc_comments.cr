require "kemal"
require "./common/**"
require "./svc/comments/**"

ServiceAuth.add_creds(SComments::CONFIG_GATEID, SComments::CONFIG_SECRET)
EventQueue.start_event_source(
  "svc_comments",
  SComments::CONFIG_MQ_HOST,
  SComments::CONFIG_MQ_PORT,
  SComments::CONFIG_MQ_USER,
  SComments::CONFIG_MQ_PASSWORD
)

Kemal.config.port = SComments::CONFIG_PORT
serve_static false
Kemal.run
