require "json"
require "base64"
require "http/client"
require "uri"
require "./config"

module SGateway
  module Client
    alias Entity = Hash(String, JSON::Type)

    @@access = {
      :users    => "",
      :posts    => "",
      :comments => "",
    }

    @@services = {
      :users    => CONFIG_SVC_USERS_ADDR,
      :posts    => CONFIG_SVC_POSTS_ADDR,
      :comments => CONFIG_SVC_COMMENTS_ADDR,
    }

    @@creds = {
      :users    => CONFIG_SVC_USERS_SECRET,
      :posts    => CONFIG_SVC_POSTS_SECRET,
      :comments => CONFIG_SVC_COMMENTS_SECRET,
    }

    def self.json_result(code, msg)
      hdr = HTTP::Headers.new
      hdr["Content-Type"] = "application/json"
      json = %( { "message": "#{code}: #{msg}" } )
      HTTP::Client::Response.new(code, json, hdr)
    end

    def self.services=(s)
      @@services = s
    end

    def self.authorize(svname)
      appid = CONFIG_APPID
      secret = @@creds[svname]
      sv = @@services[svname]
      authstr = Base64.strict_encode("#{appid}:#{secret}")
      hdr = HTTP::Headers.new
      hdr["Authorization"] = "Basic " + authstr

      res = HTTP::Client.get("#{sv}/auth", headers: hdr)
      if res.status_code < 300
        tok = parse_entity(res)
        @@access[svname] = tok["access_token"]?.to_s if tok
      end

      res
    end

    def self.request(svname, method, uri, body = nil, mime = "application/json")
      if sv = @@services[svname]
        hdr = HTTP::Headers.new
        hdr["Content-Type"] = mime
        hdr["Authorization"] = "Bearer " + @@access[svname]
        res = HTTP::Client.exec(method, "#{sv}#{uri}", body: body, headers: hdr)
        if res.status_code == 401
          res = authorize(svname)
          if res.status_code < 400
            hdr["Authorization"] = "Bearer " + @@access[svname]
            res = HTTP::Client.exec(method, "#{sv}#{uri}", body: body, headers: hdr)
          end
        end
        res
      else
        json_result(503, "No such service: `#{svname}`.")
      end
    rescue ex
      json_result(503, "Failed to connect to service `#{svname}`: #{ex.message}.")
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

    def self.get_entity(svname, uri, method = "GET") : Tuple(HTTP::Client::Response, Entity | Nil)
      res = request(svname, method, uri)
      {res, parse_entity(res)}
    end

    def self.get_oauth_token(code) : Tuple(HTTP::Client::Response, Entity | Nil)
      body = "grant_type=authorization_code&code=#{code}&client_id=#{CONFIG_APPID}"
      ct = "application/x-www-form-urlencoded"
      res = request(svname, "POST", "/oauth/token", body, ct)
      {res, parse_entity(res)}
    end
  end
end
