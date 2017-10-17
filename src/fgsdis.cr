require "random"
require "kemal"
require "./utils"
require "./fgsdis/**"

Random.new_seed

Kemal.config.public_folder = ROOT_DIR + "/static"
Kemal.config.port = 8081

Kemal.run
