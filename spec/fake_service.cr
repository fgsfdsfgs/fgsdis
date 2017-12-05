require "http"
require "http/server"

class FakeService
  def initialize(@port : Int32)
    @chan = Channel(Tuple(Int32, String, String)).new(3)
    spawn do
      echo = HTTP::Server.new(@port) do |ctx|
        sc, body, mime = @chan.not_nil!.receive
        ctx.response.content_type = mime
        ctx.response.status_code = sc
        if body == "$request"
          ctx.response.print("#{ctx.request.method} #{ctx.request.resource}")
        elsif body == "$body"
          ctx.response.print(ctx.request.body.not_nil!.gets_to_end)
        else
          ctx.response.print(body)
        end
      end
      echo.listen
    end
  end

  def push_response(status = 200, body = "", content_type = "text/plain")
    @chan.send({status, body, content_type})
  end

  def empty?
    @chan.empty?
  end
end
