require "kemal"
require "json"
require "time"
require "html"
require "uri"
require "base64"
require "../../common/helpers"
require "./config"
require "./helpers"
require "./client_model"
require "./user_model"
require "./token_model"
require "./code_model"

module SUsers
  module OAuthController
    def self.check_creds(env, email, passwd)
      return {"`username` must be set.", nil} if email == ""
      return {"`password` must be set.", nil} if passwd == ""

      passwd = sha256(passwd)
      user = User.find_by(:email, email)
      return {"Username is invalid.", nil} unless user
      return {"Password is invalid.", nil} if passwd != user.password

      {"", user}
    end

    def self.token_get_by_creds(env, client)
      email = URI.unescape(env.params.body.fetch("username", ""))
      passwd = URI.unescape(env.params.body.fetch("password", ""))

      err, user = check_creds(env, email, passwd)
      panic(env, 400, err) unless user

      env.response.content_type = "application/json"
      Token.grant(client.id, user.id, user.role).to_json
    end

    def self.token_get_by_code(env, client, redir)
      hash = env.params.body.fetch("code", "")
      panic(env, 400, "`code` must be set.") if hash == ""

      code = Code.find_by(:hash, hash)
      panic(env, 400, "Invalid code.") unless code
      panic(env, 400, "Client/code mismatch.") unless code.client_id == client.id
      panic(env, 400, "Redirect URI mismatch.") unless code.uri == redir

      token = Token.find(code.token_id)

      if !token
        code.destroy
        panic(env, 400, "No token for this code.")
      end

      if code.rotten?
        token.destroy
        code.destroy
        panic(env, 400, "Code has expired.")
      end

      code.destroy
      token.update_lifetimes

      env.response.content_type = "application/json"
      token.to_json
    end

    def self.token_refresh(env, client)
      hash = env.params.body.fetch("refresh_token", "")
      panic(env, 400, "`refresh_token` must be set.") if hash == ""

      token = Token.find_by(:refresh, hash)
      panic(env, 400, "Invalid refresh token.") unless token
      panic(env, 400, "Client/token mismatch.") unless token.client_id == client.id
      if token.refresh_rotten?
        token.destroy
        panic(env, 400, "Refresh token has expired.")
      end

      new_token = Token.grant(client.id, token.user_id, token.scope)
      token.destroy
      panic(env, 500, "Could not grant token.") unless new_token
      env.response.content_type = "application/json"
      new_token.to_json
    end

    def self.introspect(env)
      hash = env.params.body.fetch("token", "")
      panic(env, 400, "`token` must be set.") if hash == ""

      token = Token.find_by(:access, hash)
      valid = false
      msg = ""
      if !token
        msg = "The token is invalid."
      elsif token.access_rotten?
        msg = "The token has expired."
      else
        valid = true
      end

      env.response.content_type = "application/json"
      if !valid
        return %({
          "active": "false",
          "error": "#{msg}"
        })
      end

      if token
        token.update_lifetimes
        %({
          "active": "true",
          "client_id": "#{token.client_id}",
          "user_id": "#{token.user_id}",
          "access": "#{token.scope}"
        })
      else
        %({
          "active": "false",
          "error": "This isn't supposed to happen."
        })
      end
    end

    def self.request_token(env)
      client_id = env.params.body.fetch("client_id", "")
      secret = env.params.body.fetch("client_secret", "")
      panic(env, 400, "`client_id` must be set.") if client_id == ""

      client = Client.find_by(:appid, client_id)
      panic(env, 403, "No such client: #{client_id}.") unless client
      panic(env, 403, "Invalid secret.") unless client.secret == sha256(secret)

      redir = env.params.body.fetch("redirect_uri", "")
      cl_redir = client.redirect.not_nil!
      if redir == ""
        redir = cl_redir
      else
        redir = URI.unescape(redir)
      end

      panic(env, 403, "Redirect URI does not match.") unless redir == cl_redir

      grant_type = env.params.body.fetch("grant_type", "")
      env.set("event_extra", grant_type)
      case grant_type
      when "password"
        token_get_by_creds(env, client)
      when "authorization_code"
        token_get_by_code(env, client, redir)
      when "refresh_token"
        token_refresh(env, client)
      else
        panic(env, 400, "Unknown grant type.")
      end
    end

    def self.finalize_code_auth(env)
      response_type = env.params.query.fetch("response_type", "")
      client_id = env.params.query.fetch("client_id", "")
      email = URI.unescape(env.params.body.fetch("username", ""))
      passwd = URI.unescape(env.params.body.fetch("password", ""))

      panic(env, 400, "`response_type` must be `code`.") unless response_type == "code"
      panic(env, 400, "`client_id` must be set.") if client_id == ""

      client = Client.find_by(:appid, client_id)
      panic(env, 403, "No such client: #{client_id}.") unless client

      redir = env.params.query.fetch("redirect_uri", "")
      cl_redir = client.redirect.not_nil!
      if redir == ""
        redir = cl_redir
      else
        redir = URI.unescape(redir)
      end

      panic(env, 403, "Redirect URI does not match.") unless redir == cl_redir

      err, user = check_creds(env, email, passwd)
      panic(env, 400, err) unless user

      token = Token.grant(client.id, user.id, user.role)
      panic(env, 500, "Something went wrong when generating the token.") unless token
      code = Code.grant(client.id, user.id, token.id, redir)
      panic(env, 500, "Something went wrong when generating the code.") unless code

      env.redirect(redir + "?code=#{code.hash}")
    end

    def self.begin_code_auth(env)
      response_type = env.params.query.fetch("response_type", "")
      client_id = env.params.query.fetch("client_id", "")

      client = Client.find_by(:appid, client_id)
      panic(env, 403, "No such client: #{client_id}.") unless client

      redir = env.params.query.fetch("redirect_uri", "")
      cl_redir = client.redirect.not_nil!
      if redir == ""
        redir = cl_redir
      else
        redir = URI.unescape(redir)
      end

      panic(env, 403, "Redirect URI does not match.") unless redir == cl_redir

      env.redirect(
        "/oauth/login?response_type=#{response_type}&" \
        "client_id=#{client_id}&redirect_uri=#{redir}"
      )
    end
  end
end
