require "time"
require "random"
require "kemal"
require "../utils"

module HelloWorld
  GREETINGS = [
    "Hi there.",
    "Hello World!",
    "Welcome.",
    "Just a test page.",
  ]

  get "/hello" do |env|
    time = Time.now.to_s("%F %X")
    greeting = GREETINGS[Random.rand(GREETINGS.size)]
    render_view "hello"
  end
end
