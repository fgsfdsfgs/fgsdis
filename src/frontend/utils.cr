require "kemal"
require "http/client"
require "json"
require "string"
require "time"
require "./config"

ROOT_DIR = "."

macro render_view(filename)
  render("src/views/#{ {{filename}} }.ecr", "src/views/layouts/default.ecr")
end

macro render_view(filename, layout)
  render("src/views/#{ {{filename}} }.ecr", "src/views/layouts/#{ {{layout}} }.ecr")
end

def api_get(uri)
  HTTP::Client.get("#{CONFIG_GATE}#{uri}")
end

def api_post(uri, body)
  hdr = HTTP::Headers.new
  hdr["Content-Type"] = "application/json"
  HTTP::Client.post("#{CONFIG_GATE}#{uri}", hdr, body)
end

def api_put(uri, body)
  hdr = HTTP::Headers.new
  hdr["Content-Type"] = "application/json"
  HTTP::Client.put("#{CONFIG_GATE}#{uri}", hdr, body)
end

def api_delete(uri)
  HTTP::Client.delete("#{CONFIG_GATE}#{uri}")
end

def parse_json?(body)
  begin
    json = JSON.parse(body)
  rescue
    json = nil
  end
  json
end

def api_get_json(uri) : Tuple(HTTP::Client::Response, JSON::Any | Nil)
  res = api_get(uri)
  {res, parse_json?(res.body)}
end

def word_wrap(s, width = 200)
  lines = [] of String
  line = ""
  s.split(/\s+/).each do |word|
    if line.size + word.size >= width
      lines << line
      line = word
    elsif line.empty?
      line = word
    else
      line += " " + word
    end
  end
  lines << line if line
  lines
end

def word_limit(s, width = 200)
  if s.size > width
    r = word_wrap(s, width)
    return r[0] + "..."
  end
  s
end

def timefmt_long(s)
  # December 31, 2017 at 13:00
  Time.parse(s, "%FT%X").to_s("%B %-d, %Y at %R")
end

def timefmt_short(s)
  # 31/12/17 13:00
  Time.parse(s, "%FT%X").to_s("%d/%m/%y %R")
end

macro transform_response(env, r)
  {{env}}.response.status_code = {{r}}.status_code
  if %loc = {{r}}.headers["Location"]?
    {{env}}.response.headers["Location"] = %loc
  end
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{env}}.response.print({{r}}.body)
end

macro parse_json_error(env, r)
  errcode = {{r}}.status_code
  if %json = parse_json?({{r}}.body)
    if %msg = %json["message"]?
      %msgv = %msg.to_s.split(": ")
      if %msgv.size < 2
        errtext = %msg.to_s
      else
        errtext = %msgv[1]
      end
    end
  end
end

def render_error(env, r)
  errcode = 500
  errtext = "Unknown error"
  parse_json_error(env, r)
  render_view("error")
end
