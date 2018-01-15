require "sqlite3"
require "time"
require "json"
require "granite_orm/adapter/sqlite"

module SStats
  class Event < Granite::ORM::Base
    adapter sqlite
    table_name events

    field uid : String
    field service : String
    field local_id : String
    field kind : String
    field resource : String
    field response : Int32
    field extra : String
    field date : Int64
    field process_time : Int64

    validate :service, "is required", ->(this : Event) do
      this.service != nil && this.service != ""
    end

    validate :local_id, "is required", ->(this : Event) do
      this.local_id != nil && this.local_id != ""
    end

    validate :kind, "is required", ->(this : Event) do
      this.kind != nil && this.kind != ""
    end

    validate :response, "is required", ->(this : Event) do
      this.response != nil
    end

    validate :date, "is required", ->(this : Event) do
      this.date != nil
    end

    def self.from_json(str)
      json = parse_json?(str)
      return nil unless json

      e = Event.new
      e.service = json["service"]?.to_s
      e.local_id = json["local_id"]?.to_s
      e.kind = json["kind"]?.to_s
      e.resource = json["resource"]?.to_s
      e.response = json["response"]?.to_s.to_i32?
      e.extra = json["extra"]?.to_s
      e.date = json["date"]?.to_s.to_i64?
      e
    end

    def cache_uid
      t_uid = "#{@service}/#{@local_id}"
      @uid = t_uid
      t_uid
    end

    CREATE_FIELDS = {"kind", "method", "resource", "response", "extra", "date"}
  end
end
