require "kemal"
require "../utils"

module RootPage
  get "/" do |env|
    render_view "root"
  end
end
