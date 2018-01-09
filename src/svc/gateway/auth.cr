require "json"
require "http/client"
require "uri"
require "html"
require "./client"
require "./helpers"

module SGateway
  module OAuth
    def self.get_token_info(hash)
      res = Client.request(
        :users,
        "POST",
        "/oauth/introspect",
        "token=#{hash}",
        "application/x-www-form-urlencoded"
      )

      return nil unless res.status_code < 400

      Client.parse_entity(res)
    end

    def self.get_auth_info(env)
      hash = env.request.headers.fetch("Authorization", "").lchop("Bearer ")
      info = hash != "" ? get_token_info(hash) : nil
      {hash, info}
    end

    def self.get_authorized_user(env, info)
      if info
        info["user_id"].to_s
      else
        ""
      end
    end
  end
end
