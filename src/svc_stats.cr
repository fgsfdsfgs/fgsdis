require "kemal"
require "./common/errors"
require "./common/utils"
require "./svc/stats/**"

SStats::EventQueue.start_event_receiver(
  SStats::CONFIG_MQ_HOST,
  SStats::CONFIG_MQ_PORT,
  SStats::CONFIG_MQ_USER,
  SStats::CONFIG_MQ_PASSWORD
)

Kemal.config.port = SStats::CONFIG_PORT
serve_static false
Kemal.run
