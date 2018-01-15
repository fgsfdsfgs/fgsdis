require "fiber"
require "http"
require "amqp"
require "time"
require "json"
require "./model"
require "./config"

module SStats
  module EventQueue
    def self.statlog(msg)
      puts("#{Time.now} STATS: #{msg}")
    end

    def self.start_event_receiver(host, port, user, pass)
      begin
        mq_conf = AMQP::Config.new(host, port, user, pass)
        mq_conn = AMQP::Connection.new(mq_conf)

        start_job(mq_conn)
      rescue e
        statlog("FATAL: Could not connect to RabbitMQ: #{e}")
        mq_conn.close if mq_conn
      end
    end

    private def self.push_ack(chan, service, local_id, msg)
      ack = {
        "local_id" => local_id,
        "status"   => msg,
      }
      msg = AMQP::Message.new(ack.to_json)
      chan.publish(msg, "ev_ack", service.not_nil!)
    end

    private def self.start_job(conn)
      recv_chan = conn.channel
      recv_chan.on_close do |code, msg|
        statlog("Receiver channel closed: [#{code}] #{msg}.")
      end
      recv_exch = recv_chan.default_exchange
      recv_queue = recv_chan.queue("ev_dat", durable: true)

      send_chan = conn.channel
      send_chan.on_close do |code, msg|
        statlog("Sender channel closed: [#{code}] #{msg}.")
      end
      send_exch = send_chan.exchange("ev_ack", "direct")

      recv_queue.subscribe do |msg|
        msg.ack

        statlog("Receiving new event...")

        ev = Event.from_json(msg.to_s)
        unless ev
          statlog("ERROR: Could not parse received event:\n`#{msg.to_s}`")
          next
        end

        uid = ev.cache_uid

        unless ev.valid?
          statlog("Event `#{uid}` has invalid contents, discarding: #{ev.errors[0]}.")
          push_ack(send_chan, ev.service, ev.local_id, "error") if ev.local_id && ev.service
          next
        end

        oev = Event.find_by(:uid, uid)
        if oev
          statlog("Event `#{uid}` was already received, discarding.")
          push_ack(send_chan, ev.service, ev.local_id, "duplicate")
          next
        end

        statlog("Processing event:\n#{ev.to_pretty_json}")

        if ev.save
          statlog("Event `#{uid}` successfully processed and saved.")
          push_ack(send_chan, ev.service, ev.local_id, "ok")
        else
          statlog("ERROR: Could not save event `#{uid}`: #{ev.errors[0]}!")
          push_ack(send_chan, ev.service, ev.local_id, "err")
        end
      end
    end
  end
end
