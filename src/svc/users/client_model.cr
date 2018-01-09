require "sqlite3"
require "granite_orm/adapter/sqlite"

module SUsers
  class Client < Granite::ORM::Base
    adapter sqlite
    table_name oauth_clients

    field appid : String
    field secret : String
    field host : String
    field redirect : String

    has_many :tokens
    has_many :codes

    validate :appid, "is required", ->(this : Client) do
      this.appid != nil && this.appid != ""
    end

    validate :secret, "is required", ->(this : Client) do
      this.secret != nil && this.secret != ""
    end

    validate :host, "is required", ->(this : Client) do
      this.host != nil && this.host != ""
    end

    validate :redirect, "is required", ->(this : Client) do
      this.redirect != nil && this.redirect != ""
    end
  end
end
