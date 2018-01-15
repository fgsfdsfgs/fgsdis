require "fiber"
require "random"
require "amqp"
require "json"
require "kemal"
require "./utils"
require "./concurrent_hash"
require "./ticker"

module EventQueue
  NUM_RETRIES   =  3
  RETRY_TIMEOUT =  5
  CHAN_SIZE     = 16

  class Event
    property service : String
    property date : Time
    property local_id : String
    property kind : String
    property resource : String
    property response : Int32
    property extra : String
    property life : Int32

    def uid
      "#{@service}/#{@local_id}"
    end

    def generate_local_id
      date_str = @date.epoch.to_s(16).rjust(8, '0')
      ns_str = @date.nanosecond.to_s(16).rjust(8, '0')
      rnd_str = Random.rand(0xffffffffu32).to_s(16).rjust(8, '0')
      "#{date_str}#{ns_str}#{rnd_str}"
    end

    def initialize(@service : String, @kind : String)
      @life = NUM_RETRIES
      @date = Time.utc_now
      @local_id = generate_local_id
      @resource = ""
      @response = 0
      @extra = ""
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field("service", service)
        json.field("kind", kind)
        json.field("date", date.epoch.to_s)
        json.field("local_id", local_id)
        json.field("resource", resource)
        json.field("response", response.to_s)
        json.field("extra", extra)
      end
    end
  end

  @@service = ""
  @@resend = ConcurrentHash(String, Event).new
  @@chan_events = Channel(Event).new(CHAN_SIZE)

  def self.start_event_source(service, host, port, user, pass)
    @@service = service

    begin
      mq_conf = AMQP::Config.new(host, port, user, pass)
      mq_conn = AMQP::Connection.new(mq_conf)

      start_send_job(mq_conn)
      start_recv_job(mq_conn)
    rescue e
      statlog("FATAL: Could not connect to RabbitMQ: #{e}")
      mq_conn.close if mq_conn
    end
  end

  def self.statlog(msg)
    puts("#{Time.now} STATS: #{msg}")
  end

  def self.push_event(kind, resource, response, extra = "")
    event = Event.new(@@service.not_nil!, kind)
    event.resource = resource
    event.response = response
    event.extra = extra

    @@chan_events.send(event)
  end

  def self.add_to_resend(event)
    @@resend[event.local_id] = event
  end

  def self.get_from_resend?(local_id)
    @@resend.delete(local_id)
  end

  private def self.send_to_mq(chan, ev)
    msg = AMQP::Message.new(ev.to_json, AMQP::Protocol::Properties.new(delivery_mode: 2u8))
    chan.publish(msg, "", "ev_dat")
  end

  private def self.send_new_event(chan, ev)
    statlog("New event:\n#{ev.to_pretty_json}")
    send_to_mq(chan, ev)
    statlog("New event `#{ev.local_id}` sent to queue.")
    add_to_resend(ev)
  end

  private def self.resend_events(chan)
    to_delete = [] of String

    statlog("Resending events...")
    @@resend.each do |local_id, ev|
      print("    #{local_id}... ")
      send_to_mq(chan, ev)
      ev.life -= 1
      to_delete << local_id if ev.life == 0
      puts("OK, #{ev.life} tries left")
    end

    if !to_delete.empty?
      statlog("Ran out of resend tries for events:")
      to_delete.each do |v|
        puts("    #{v}")
      end
      @@resend.delete_all(to_delete)
    end
  end

  private def self.start_send_job(conn)
    send_chan = conn.channel
    send_chan.on_close do |code, msg|
      statlog("Sender channel closed: [#{code}] #{msg}.")
    end
    send_exch = send_chan.default_exchange
    send_queue = send_chan.queue("ev_dat", durable: true)

    chan_ticker = ticker(RETRY_TIMEOUT.seconds)

    spawn do
      loop do
        select
        when ev = @@chan_events.receive
          send_new_event(send_chan, ev)
        when t = chan_ticker.receive
          resend_events(send_chan)
        end
      end
    end
  end

  private def self.start_recv_job(conn)
    recv_chan = conn.channel
    recv_chan.on_close do |code, msg|
      statlog("Receiver channel closed: [#{code}] #{msg}.")
    end
    recv_exch = recv_chan.exchange("ev_ack", "direct")
    recv_queue = recv_chan.queue("", exclusive: true)
    recv_queue.bind(recv_exch, key: @@service.not_nil!)

    recv_queue.subscribe(no_ack: true) do |msg|
      ack = parse_json?(msg.to_s)
      unless ack
        statlog("ERROR: Got ack that wasn't JSON-encoded!")
        next
      end

      local_id = ack["local_id"]?.to_s

      if ev = get_from_resend?(local_id)
        status = ack["status"]?.to_s
        if status == "ok"
          statlog("Got success ack for event `#{local_id}`.")
        elsif status == "error"
          statlog("Got error ack for event `#{local_id}`.")
        elsif status == "duplicate"
          statlog("Got duplicate ack for event `#{local_id}`.")
        else
          statlog("Got malformed ack for event `#{local_id}`.")
        end
      else
        statlog("ERROR: Got response for event `#{local_id}`, which is not in the wait list!")
      end
    end
  end

  # HACK: have to manually replace the logger to capture all possible events
  class EventLogger < Kemal::BaseLogHandler
    @io : IO

    def initialize(@io : IO = STDOUT)
    end

    def call(context : HTTP::Server::Context)
      time = Time.now
      call_next(context)
      elapsed_text = elapsed_text(Time.now - time)
      @io << time << " " << context.response.status_code << " " << context.request.method << " " << context.request.resource << " " << elapsed_text << "\n"
      EventQueue.push_event(
        context.request.method,
        context.request.resource,
        context.response.status_code
      )
      context
    end

    def write(message : String)
      @io << message
    end

    private def elapsed_text(elapsed)
      millis = elapsed.total_milliseconds
      return "#{millis.round(2)}ms" if millis >= 1

      "#{(millis * 1000).round(2)}µs"
    end
  end

  unless ENV["KEMAL_ENV"]? == "test"
    Kemal.config.logger = EventLogger.new
  end
end
