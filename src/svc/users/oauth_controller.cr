require "kemal"
require "json"
require "time"
require "html"
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
    def self.token_get_by_creds(env, client)
      email = HTML.unescape(env.params.body.fetch("username", ""))
      passwd = HTML.unescape(env.params.body.fetch("password", ""))
      panic(env, 400, "`username` must be set.") if email == ""
      panic(env, 400, "`password` must be set.") if passwd == ""

      passwd = sha256(passwd)
      user = User.find_by(:email, email)
      panic(env, 400, "Username is invalid.") unless user
      panic(env, 400, "Password is invalid.") if passwd != user.password

      env.response.content_type = "application/json"
      Token.grant(client.id, user.id)
    end

    def self.token_get_by_code(env, client, redir)
      hash = env.params.body.fetch("code", "")
      panic(env, 400, "`code` must be set.") if hash == ""

      code = Code.find_by(:hash, hash)
      panic(env, 400, "Invalid code.") unless code
      panic(env, 400, "Client/code mismatch.") unless code.client_id == client.id
      panic(env, 400, "Code has expired.") if code.rotten?
      panic(env, 400, "Redirect URI mismatch.") unless code.uri == redir

      panic(env, 500, code.errors[0]) unless code.destroy
      env.response.content_type = "application/json"
      Token.grant(client.id)
    end

    def self.token_refresh(env, client)
      hash = env.params.body.fetch("refresh_token", "")
      panic(env, 400, "`refresh_token` must be set.") if hash == ""

      token = Token.find_by(:refresh, hash)
      panic(env, 400, "Invalid refresh token.") unless token
      panic(env, 400, "Client/token mismatch.") unless token.client_id == client.id
      panic(env, 400, "Refresh token has expired.") if token.refresh_rotten?

      new_token = Token.grant(client.id, token.user_id)
      panic(env, 500, token.errors[0]) unless token.destroy
      env.response.content_type = "application/json"
      new_token
    end

    def self.token_validate(env, client)
      hash = env.params.body.fetch("access_token", "")
      user_id = env.params.body["user_id"]?
      panic(env, 400, "`access_token` must be set.") if hash == ""

      token = Token.find_by(:access, hash)
      valid = false
      msg = "???"
      if !token
        msg = "The token is invalid."
      elsif token.client_id != client.id
        msg = "Client/token mismatch."
      elsif token.access_rotten?
        msg = "The token has expired."
      elsif token.user_id != user_id
        msg = "User/token mismatch."
      else
        valid = true
        msg = "The token is valid."
      end

      env.response.content_type = "application/json"
      %({
        "valid": #{valid},
        "message": "#{msg}"
        })
    end

    def self.request_token(env)
      client_id = env.params.body.fetch("client_id", "")
      secret = env.params.body.fetch("client_secret", "")
      panic(env, 400, "`client_id` must be set.") if client_id == ""

      client = Client.find_by(:appid, client_id)
      panic(env, 403, "No such client: #{client_id}.") unless client
      panic(env, 403, "Invalid secret.") unless client.secret == sha256(secret)

      redir = env.params.body.fetch("redirect_uri", "")
      if redir == ""
        redir = client.redirect
      else
        redir = HTML.unescape(redir)
      end

      grant_type = env.params.body.fetch("grant_type", "")
      case grant_type
      when "client_credentials"
        token_get_by_creds(env, client)
      when "authorization_code"
        token_get_by_code(env, client, redir)
      when "refresh_token"
        token_refresh(env, client)
      else
        panic(env, 400, "Unknown grant type.")
      end
    end

    def self.request_code(env)
      response_type = env.params.query.fetch("response_type", "")
      client_id = env.params.query.fetch("client_id", "")

      panic(env, 400, "`response_type` must be `code`.") unless response_type == "code"
      panic(env, 400, "`client_id` must be set.") if client_id == ""

      client = Client.find_by(:appid, client_id)
      panic(env, 403, "No such client: #{client_id}.") unless client

      redir = env.params.query.fetch("redirect_uri", "")
      cl_redir = client.redirect.not_nil!
      if redir == ""
        redir = cl_redir
      else
        redir = HTML.unescape(redir)
      end

      code = Code.grant(client.id, redir)
      panic(env, 500, "Something went wrong when generating the code.") unless code
      env.redirect(redir + "?code=#{code}")
    end
  end
end
