require "http"
require "html"
require "time"
require "kemal"
require "./utils"
require "./helpers"

module ServiceAuth
  @@appid = ""
  @@secret = ""

  module Token
    TOKEN_EXP_TIME = 60000 # msec

    @@date = Time.now
    @@exp_date = Time.now
    @@hash = ""

    def self.grant : String
      @@date = Time.now
      @@exp_date = @@date + TOKEN_EXP_TIME.milliseconds
      @@hash = sha256(@@date.not_nil!.to_s)
      %( {
        "access_token": "#{@@hash}",
        "token_type": "bearer",
        "expires_in": #{TOKEN_EXP_TIME}
      } )
    end

    def self.rotten?
      Time.now > @@exp_date
    end

    def self.valid?(token)
      token == @@hash && !self.rotten?
    end
  end

  def self.valid_creds?(appid, secret)
    myappid = @@appid.not_nil!
    if myappid == appid
      mysecret = @@secret.not_nil!
      secret = sha256(secret)
      return mysecret == secret
    end
    false
  end

  def self.set_creds(appid, secret)
    @@appid = appid
    @@secret = sha256(secret)
  end

  class ServiceAuthHandler < Kemal::Handler
    exclude ["/auth"]

    def call(env)
      return call_next(env) if exclude_match?(env)

      auth = env.request.headers["Authorization"]?
      if !auth || !auth.starts_with?("Bearer ")
        env.response.headers["WWW-Authenticate"] = %(Bearer realm="/*")
        panic(env, 401, "Provide a bearer token.")
      end

      token = auth.lchop("Bearer ")
      panic(env, 401, "Provided token is invalid.") if !Token.valid?(token)

      call_next(env)
    end
  end

  get "/auth" do |env|
    appid = env.params.query.fetch("appid", "")
    secret = env.params.query.fetch("secret", "")

    panic(env, 400, "`appid` must be specified.", :next) if appid == ""
    panic(env, 400, "`secret` must be specified.", :next) if secret == ""

    if !valid_creds?(appid.to_s, secret.to_s)
      panic(env, 403, "Invalid credentials.", :next)
    end

    env.response.content_type = "application/json"
    Token.grant
  end

  add_handler(ServiceAuthHandler.new)
end
