require "redis"
require "./config"

module SGateway
  module RequestQueue
    unless ENV["KEMAL_ENV"]? == "test"
      @@context = Redis.new(url: CONFIG_REDIS_ADDR)
    else
      @@context = nil
    end

    def self.push(service, method, uri, body, mime)
      command = "#{method} #{uri} #{mime} #{body}"
      if ctx = @@context
        ctx.lpush(service.to_s, command)
      end
    end
  end
end
