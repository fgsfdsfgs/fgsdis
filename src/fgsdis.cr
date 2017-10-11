require "random"
require "kemal"
require "./utils"
require "./fgsdis/**"

Random.new_seed

Kemal.config.public_folder = ROOT_DIR + "/public"
Kemal.config.port = 8081

# Kemal doesn't serve /index.html by default
get "/" do |env|
  env.redirect "/index.html"
end

Kemal.run
