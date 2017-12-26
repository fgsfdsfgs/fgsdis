require "fiber"
require "deque"
require "http"
require "./config"
require "./client"

module SGateway
  module Client
    module RequestQueue
      alias QueueRequest = Tuple(Symbol, String, String, String, String)
      @@queue = Deque(QueueRequest).new

      def self.push(svname, method, uri, body, mime)
        @@queue.push({svname, method, uri, body, mime})
      end

      private def self.work
        loop do
          while @@queue.empty?
            Fiber.sleep(1)
          end

          @@queue.size.times do
            req = @@queue.shift
            res = Client.request(*req)
            if res.status_code == 503
              @@queue.push(req)
            end
          end
        end
      end

      spawn work
    end

    def self.queue_request(svname, method, uri, body = nil, mime = "application/json")
      res = request(svname, method, uri, body, mime)
      if res.status_code == 503
        RequestQueue.push(svname, method, uri, body ? body : "", mime)
        json_result(202, "Operation pending.")
      else
        res
      end
    end
  end
end
