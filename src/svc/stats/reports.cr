require "time"
require "./model"

module SStats
  module Reports
    def self.posts_per_hour(from, to)
      events = Event.all(
        "WHERE service = 'svc_posts'" \
        " AND kind = 'POST'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[] of Int32, [] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.comments_per_hour(from, to)
      events = Event.all(
        "WHERE service = 'svc_comments'" \
        " AND kind = 'POST'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[] of Int32, [] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.page_visits(from, to)
      events = Event.all(
        "WHERE kind = 'GET'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[] of Int32, [] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.auth_successes(from, to)
      events = Event.all(
        "WHERE service = 'svc_users'" \
        " AND resource = '/oauth/token'" \
        " AND kind = 'POST'" \
        " AND response = 200" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[] of Int32, [] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.auth_failures(from, to)
      events = Event.all(
        "WHERE service = 'svc_users'" \
        " AND resource LIKE '/oauth/%'" \
        " AND resource <> '/oauth/introspect'" \
        " AND response <> 200" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[] of Int32, [] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end
  end
end
