require "redis"
require "./config"

module SGateway
  module RequestQueue
    begin
      @@context = Redis.new(url: CONFIG_REDIS_ADDR)
    rescue
      @@context = nil
      puts("WARNING: Could not connect to Redis at #{CONFIG_REDIS_ADDR}.")
      puts("         Job queueing will be unavailable.")
    end

    def self.push(service, method, uri, body, mime)
      command = "#{method} #{uri} #{mime} #{body}"
      if ctx = @@context
        ctx.lpush(service.to_s, command)
      end
    end
  end
end
