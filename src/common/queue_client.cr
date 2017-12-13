require "http"
require "io"
require "kemal"
require "redis"

module RequestQueue
  class Client
    def initialize(@addr : String, @queue : String)
      @redis = Redis.new(url: @addr)
      @wants_close = false
    end

    def ready
      @redis != nil
    end

    def fetch? : HTTP::Request?
      if commands = @redis.brpop([@queue], 1)
        if commands.size == 2
          args = commands[1].to_s.split(' ', 4)
          return nil unless args.size == 4
          method = args[0]
          uri = args[1]
          hdr = HTTP::Headers.new
          hdr["Content-Type"] = args[2]
          body = args[3]
          HTTP::Request.new(method, uri, hdr, body)
        end
      end
    end

    private def kemal_handle(request)
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)
      Kemal.config.handlers.first.call(context)
    end

    def listen
      until @wants_close
        if r = fetch?
          kemal_handle(r)
        end
      end
    end
  end

  def self.attach_to(address : String, queue : String)
    spawn do
      q = RequestQueue::Client.new(address, queue)
      q.listen
    end
  end

  def self.attach_to?(address : String, queue : String)
    spawn do
      begin
        q = RequestQueue::Client.new(address, queue)
      rescue
        puts("WARNING: Could not connect to Redis at #{address}.")
        puts("         Queued jobs will be unavailable.")
      else
        q.listen
      end
    end
  end
end
