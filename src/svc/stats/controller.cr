require "kemal"
require "json"
require "time"
require "html"
require "uri"
require "../../common/utils"
require "../../common/helpers"
require "./config"
require "./model"
require "./reports"

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

    def self.get_report_by_name(report, from, to)
      case report
      when "pph"
        x, y = Reports.posts_per_hour(from, to)
      when "cph"
        x, y = Reports.comments_per_hour(from, to)
      when "auth_ok"
        x, y = Reports.auth_successes(from, to)
      when "auth_fail"
        x, y = Reports.auth_failures(from, to)
      when "views"
        x, y = Reports.page_visits(from, to)
      else
        x, y = {nil, nil}
      end

      {x, y}
    end

    def self.generate_report(env)
      report = env.params.url.fetch("report", "")
      from_arg = env.params.query.fetch("from", "").to_i64?
      to_arg = env.params.query.fetch("to", "").to_i64?

      from = from_arg ? Time.epoch(from_arg) : Time.epoch(0)
      to = to_arg ? Time.epoch(to_arg) : Time.utc_now

      x, y = get_report_by_name(report, from, to)
      panic(env, 400, "Unknown report ID.") unless x && y

      env.response.content_type = "application/json"
      %({
        "report": "#{report}",
        "from": "#{from.to_s}",
        "to": "#{to.to_s}",
        "x": #{x.to_json},
        "y": #{y.to_json}
      })
    end

    def self.generate_all_reports(env)
      report = env.params.url.fetch("report", "")
      from_arg = env.params.query.fetch("from", "").to_i64?
      to_arg = env.params.query.fetch("to", "").to_i64?

      from = from_arg ? Time.epoch(from_arg) : Time.epoch(0)
      to = to_arg ? Time.epoch(to_arg) : Time.utc_now

      res = "{\n"
      ["pph", "cph", "auth_ok", "auth_fail", "views"].each do |report|
        x, y = get_report_by_name(report, from, to)
        res += %(
          "#{report}": {
            "from": "#{from.to_s}",
            "to": "#{to.to_s}",
            "x": #{x.to_json},
            "y": #{y.to_json}
          })
        res += ",\n" unless report == "views"
      end
      res += "\n}"

      env.response.content_type = "application/json"
      res
    end
  end
end
