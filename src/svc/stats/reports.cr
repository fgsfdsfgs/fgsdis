require "time"
require "./model"

module SStats
  module Reports
    def self.posts_per_hour(from, to)
      events = Event.all(
        "WHERE service = 'svc_posts'" \
        " AND kind = 'POST'" \
        " AND resource = '/post'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[0, 23] of Int32, [0, 0] of Int32} if events.empty?

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
        " AND resource = '/comment'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[0, 23] of Int32, [0, 0] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.activity(from, to)
      events = Event.all(
        "WHERE date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      return {[0, 23] of Int32, [0, 0] of Int32} if events.empty?

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

      return {[0, 23] of Int32, [0, 0] of Int32} if events.empty?

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

      return {[0, 23] of Int32, [0, 0] of Int32} if events.empty?

      y = Array(Int32).new(24, 0)

      events.each do |ev|
        date = Time.epoch(ev.date.not_nil!)
        y[date.hour] += 1
      end

      {(0i32...24i32).to_a, y}
    end

    def self.posts_info(from, to)
      events = Event.all(
        "WHERE service = 'svc_posts'" \
        " AND kind = 'POST'" \
        " AND resource = '/post'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      x = [0, 1, 2]
      y = [0, 0f64, 0]
      unless events.empty?
        h = Array(Int32).new(24, 0)

        events.each do |ev|
          date = Time.epoch(ev.date.not_nil!)
          h[date.hour] += 1
        end

        y[0] = h.reduce { |acc, x| acc += x }
        y[1] = y[0].to_f64 / 24.0
      end

      events = Event.all(
        "WHERE service = 'svc_posts'" \
        " AND kind = 'DELETE'" \
        " AND response = 200" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )
      y[2] = events.size

      {x, y}
    end

    def self.comments_info(from, to)
      events = Event.all(
        "WHERE service = 'svc_comments'" \
        " AND kind = 'POST'" \
        " AND resource = '/comment'" \
        " AND response = 201" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      x = [0, 1]
      y = [0, 0f64, 0]
      unless events.empty?
        h = Array(Int32).new(24, 0)

        events.each do |ev|
          date = Time.epoch(ev.date.not_nil!)
          h[date.hour] += 1
        end

        y[0] = h.reduce { |acc, x| acc += x }
        y[1] = y[0].to_f64 / 24.0
      end

      events = Event.all(
        "WHERE service = 'svc_comments'" \
        " AND kind = 'DELETE'" \
        " AND response = 200" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )
      y[2] = events.size

      {x, y}
    end

    def self.users_info(from, to)
      epass = Event.all(
        "WHERE service = 'svc_users'" \
        " AND resource = '/oauth/token'" \
        " AND kind = 'POST'" \
        " AND response = 200" \
        " AND extra = 'authorization_code'" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      ecode = Event.all(
        "WHERE service = 'svc_users'" \
        " AND resource = '/oauth/token'" \
        " AND kind = 'POST'" \
        " AND response = 200" \
        " AND extra = 'password'" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      erefr = Event.all(
        "WHERE service = 'svc_users'" \
        " AND resource = '/oauth/token'" \
        " AND kind = 'POST'" \
        " AND response = 200" \
        " AND extra = 'refresh_token'" \
        " AND date BETWEEN #{from.epoch} AND #{to.epoch}"
      )

      x = [0, 1, 2]
      y = [epass.size, ecode.size, erefr.size]

      {x, y}
    end

    def self.general_info(from, to)
      ax, ay = activity(from, to)

      x = [0, 1]
      y = [0, 0f64]
      y[0] = ay.reduce { |acc, x| acc += x }
      y[1] = y[0].to_f64 / 24.0

      {x, y}
    end
  end
end
