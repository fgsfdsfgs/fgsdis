require "sqlite3"
require "time"
require "granite_orm/adapter/sqlite"

module SUsers
  class Code < Granite::ORM::Base
    adapter sqlite
    table_name oauth_codes

    field hash : String
    field uri : String
    field issued : Int64
    field expires : Int64

    belongs_to :client

    validate :hash, "is required", ->(this : Code) do
      this.hash != nil && this.hash != ""
    end

    validate :issued, "is required", ->(this : Code) do
      this.issued != nil && this.issued != 0
    end

    def rotten?
      if exp = @expires
        Time.now.epoch >= exp
      else
        false
      end
    end

    def self.grant(client_id, redir = "")
      now = Time.now.epoch
      code = Code.new
      code.uri = redir
      code.client_id = client_id
      code.hash = sha256(now.to_s)
      code.issued = now
      code.expires = now + CONFIG_OAUTH_CODE_LIFETIME
      return nil unless code.valid?
      return nil unless code.save
      code.hash
    end
  end
end
