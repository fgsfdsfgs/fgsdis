require "http"
require "html"
require "time"
require "base64"
require "kemal"
require "./utils"
require "./helpers"

module ServiceAuth
  struct BasicToken
    EXP_TIME = 60 # sec

    property appid : String
    property issued : Time
    property expires : Time
    property hash : String

    def initialize(@appid : String)
      @issued = Time.now
      @expires = @issued + EXP_TIME.seconds
      @hash = sha256(@issued.not_nil!.to_s)
    end

    def rotten?
      Time.now > @expires
    end

    def to_json
      %( {
        "access_token": "#{@hash}",
        "token_type": "bearer",
        "expires_in": #{EXP_TIME}
      } )
    end
  end

  class ServiceAuthHandler < Kemal::Handler
    exclude ["/auth"]

    def call(env)
      return call_next(env) if exclude_match?(env) || ServiceAuth.skip?(env)

      auth = env.request.headers["Authorization"]?
      if !auth || !auth.starts_with?("Bearer ")
        env.response.headers["WWW-Authenticate"] = %(Bearer realm="/*")
        panic(env, 401, "Provide a bearer token.")
      end

      token = auth.lchop("Bearer ")
      panic(env, 401, "Provided token is invalid.") if !ServiceAuth.token_valid?(token)

      call_next(env)
    end
  end

  @@creds = {} of String => String
  @@tokens = {} of String => BasicToken
  @@disabled = false

  def self.skip?(env)
    Kemal.config.env == "test" || @@disabled
  end

  def self.valid_creds?(appid, secret)
    if mysecret = @@creds[appid]?
      mysecret == sha256(secret)
    else
      false
    end
  end

  def self.add_creds(appid, secret)
    @@creds[appid] = sha256(secret)
  end

  def self.disable
    @@disabled = true
  end

  def self.token_valid?(hash)
    if mytoken = @@tokens[hash]?
      if mytoken.rotten?
        @@tokens.delete(hash)
        false
      else
        true
      end
    else
      false
    end
  end

  def self.grant_token(appid)
    t = BasicToken.new(appid)
    @@tokens[t.hash] = t
    t
  end

  get "/auth" do |env|
    auth = env.request.headers["Authorization"]?
    if !auth || !auth.starts_with?("Basic ")
      env.response.headers["WWW-Authenticate"] = %(Basic realm="/*")
      panic(env, 401, "Provide basic auth credentials.", :next)
    end

    creds = Base64.decode_string(auth.lchop("Basic ")).split(':')
    panic(env, 400, "Invalid `Authorization` header.", :next) if creds.size != 2

    appid = creds[0]
    secret = creds[1]

    panic(env, 400, "`appid` must be specified.", :next) if appid == ""
    panic(env, 400, "`secret` must be specified.", :next) if secret == ""

    if !valid_creds?(appid.to_s, secret.to_s)
      panic(env, 403, "Invalid credentials.", :next)
    end

    env.response.content_type = "application/json"
    grant_token(appid).to_json
  end

  add_handler(ServiceAuthHandler.new)
end
