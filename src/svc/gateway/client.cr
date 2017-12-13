require "json"
require "http/client"
require "uri"
require "./config"
require "./queue_server"

module SGateway
  module Client
    alias Entity = Hash(String, JSON::Type)

    @@services = {
      :users    => CONFIG_SVC_USERS_ADDR,
      :posts    => CONFIG_SVC_POSTS_ADDR,
      :comments => CONFIG_SVC_COMMENTS_ADDR,
    }

    def self.services=(s)
      @@services = s
    end

    def self.request(svname, method, uri, body = nil, mime = "application/json")
      if sv = @@services[svname]
        hdr = HTTP::Headers.new
        hdr["Content-Type"] = mime
        HTTP::Client.exec(method, "#{sv}#{uri}", body: body, headers: hdr)
      else
        HTTP::Client::Response.new(503, "No such service: `#{svname}`.")
      end
    rescue
      HTTP::Client::Response.new(503, "Failed to connect to service `#{svname}`.")
    end

    def self.queue_request(svname, method, uri, body = nil, mime = "application/json")
      if sv = @@services[svname]
        hdr = HTTP::Headers.new
        hdr["Content-Type"] = mime
        HTTP::Client.exec(method, "#{sv}#{uri}", body: body, headers: hdr)
      else
        HTTP::Client::Response.new(503, "No such service: `#{svname}`.")
      end
    rescue
      RequestQueue.push(svname, method, uri, body ? body : "", mime)
      HTTP::Client::Response.new(202, "Operation pending.")
    end

    def self.parse_entity(res) : Entity | Nil
      if res.status_code == 200 && res.content_type == "application/json"
        begin
          ent = {} of String => JSON::Type

          case json = JSON.parse(res.body).raw
          when Hash
            json.each do |k, v|
              ent[k] = v.as(JSON::Type)
            end
          when Array
            ent["_json"] = json
          end

          return ent
        rescue
          return nil
        end
      else
        return nil
      end
    end

    def self.get_entity(svname, uri) : Tuple(HTTP::Client::Response, Entity | Nil)
      res = request(svname, "GET", uri)
      {res, parse_entity(res)}
    end
  end
end
