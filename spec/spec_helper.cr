require "spec"
require "http"
require "kemal"
require "../src/fgsdis/**"

def build_main_handler
  Kemal.config.setup
  main_handler = Kemal.config.handlers.first
  current_handler = main_handler
  Kemal.config.handlers.each_with_index do |handler, index|
    current_handler.next = handler
    current_handler = handler
  end
  main_handler
end

def test_request(request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  main_handler = build_main_handler
  main_handler.call context
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

Spec.before_each do
  Kemal.config.env = "development"
  Kemal.config.logging = false
end

Spec.after_each do
  Kemal.config.clear
end
