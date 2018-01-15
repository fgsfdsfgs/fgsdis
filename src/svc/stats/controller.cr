require "kemal"
require "json"
require "time"
require "html"
require "uri"
require "../../common/utils"
require "../../common/helpers"
require "./config"
require "./model"

module SStats
  module Controller
    def self.get_all(env)
      env.response.content_type = "application/json"
      return Event.all.to_json
    end

    def self.get(env)
      e = nil
      get_requested_entity(env, Event, e)
      env.response.content_type = "application/json"
      e.to_json
    end

    def self.get_filtered(env)
      service = env.params.url.fetch("service", "")
      kind = env.params.query.fetch("kind", "")
      response = env.params.query.fetch("response", "").to_i64?
      resource = URI.unescape(env.params.query.fetch("resource", ""))
      from = env.params.query.fetch("from", "").to_i64?
      to = env.params.query.fetch("to", "").to_i64?

      panic(env, 400, "`service` must be set.") if service == ""

      clause = "WHERE service = #{service}"
      clause += " AND kind = #{kind}" unless kind == ""
      clause += " AND response = #{response}" if response
      clause += " AND resource = #{resource}" if resource
      clause += " AND time >= #{from}" if from
      clause += " AND time <= #{to}" if to

      events = Event.all(clause)
      env.response.content_type = "application/json"
      events.to_json
    end

    def self.create(env)
      service = env.params.url.fetch("service", "")
      panic(env, 400, "`service` must be set.") if service == ""

      attrs = env.params.json.select(Event::CREATE_FIELDS)
      panic(env, 400, "No relevant fields in JSON.") if attrs.empty?

      e = Event.new(attrs)
      e.service = service

      panic(env, 400, e.errors[0]) unless e.valid?

      oe = Event.find_by(:date, e.date)
      panic(env, 403, "This event has already been saved.") if oe

      e.resource = URI.escape(e.resource.not_nil!)
      panic(env, 500, e.errors[0]) unless e.save

      created(env, "/stats/event/#{e.id}")
    end
  end
end
