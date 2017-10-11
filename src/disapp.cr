require "random"
require "kemal"
require "./disapp/**"

Random.new_seed

Kemal.config.public_folder = "~/.disapp/public"
Kemal.config.port = 8081

# Kemal doesn't serve index.html by default
get "/" do |env|
  env.redirect "/index.html"
end

Kemal.run
