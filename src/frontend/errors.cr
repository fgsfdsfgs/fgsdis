require "kemal"
require "./utils"

error 404 do |env|
  errcode = 404
  errtext = "Nothing here."
  render_view("error")
end
