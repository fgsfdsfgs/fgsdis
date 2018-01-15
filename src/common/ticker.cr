require "fiber"
require "time"

def ticker(interval : Time::Span, bufsiz = 16)
  chan = Channel(Int64).new(bufsiz)
  spawn do
    count = 0i64
    loop do
      Fiber.sleep(interval)
      chan.send(count)
      count += 1
    end
  end
  chan
end
