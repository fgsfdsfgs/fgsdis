require "sqlite3"
require "time"
require "granite_orm/adapter/sqlite"
require "./user_model"

module SUsers
  class Token < Granite::ORM::Base
    adapter sqlite
    table_name oauth_tokens

    field user_id : Int64 # HACK: granite doesn't support optional relations
    field access : String
    field refresh : String
    field issued : Int64
    field used : Int64
    field access_expires : Int64
    field refresh_expires : Int64

    belongs_to :client

    validate :access, "is required", ->(this : Token) do
      this.access != nil && this.access != ""
    end

    validate :refresh, "is required", ->(this : Token) do
      this.refresh != nil && this.refresh != ""
    end

    validate :issued, "is required", ->(this : Token) do
      this.issued != nil && this.issued != 0
    end

    # HACK: granite doesn't support optional relations (2)
    def user
      if uid = @user_id
        User.find(uid)
      else
        nil
      end
    end

    def access_rotten?
      if exp = @access_expires
        Time.now.epoch >= exp
      else
        false
      end
    end

    def refresh_rotten?
      if exp = @refresh_expires
        Time.now.epoch >= exp
      else
        false
      end
    end

    def self.grant(client_id, user_id = nil)
      now = Time.now.epoch
      token = Token.new
      token.client_id = client_id
      token.user_id = user_id
      token.access = sha256(now.to_s + "A")
      token.refresh = sha256(now.to_s + "R")
      token.issued = now
      token.used = now
      token.access_expires = now + CONFIG_OAUTH_ACCESS_LIFETIME
      token.refresh_expires = now + CONFIG_OAUTH_REFRESH_LIFETIME
      return nil unless token.valid?
      return nil unless token.save
      %({
        "access_token": "#{token.access}",
        "refresh_token": "#{token.refresh}",
        "token_type": "bearer",
        "expires_in": #{CONFIG_OAUTH_ACCESS_LIFETIME}
      })
    end
  end
end
