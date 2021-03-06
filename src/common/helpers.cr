require "kemal"
require "time"
require "html"
require "./utils"

macro get_requested_entity(env, model, target)
  %id = {{env}}.params.url.fetch("id", "").to_i64?
  panic({{env}}, 400, "ID must be an Int.") unless %id
  {{target}} = {{model}}.find(%id)
  panic({{env}}, 404, "{{model}} not found.") unless {{target}}
end

macro print_json_message(env, c, m)
  %str = "#{ {{c}} }: " + {{m}}.to_s
  {{env}}.response.status_code = {{c}}
  {{env}}.response.content_type = "application/json"
  {{env}}.response.print(%( { "message": "#{ %str }" } ))
end

macro panic(env, c, m, ret = :return)
  print_json_message({{env}}, {{c}}, {{m}})
  {{env}}.response.close
  {% if ret == :return %}
    return
  {% elsif ret == :next %}
    next
  {% end %}
end

macro created(env, uri)
  {{env}}.response.status_code = 201
  {{env}}.response.headers["Location"] = {{uri}}
  {{env}}.response.close
end

macro paginated_entity_list(env, model, filter = "", order = false)
  %result = [] of {{model}}

  %start = 0
  %psize = 0
  if {{env}}.params.query.has_key?("page")
    %psize = {{env}}.params.query.fetch("size", "10").to_i64?
    %pstart = {{env}}.params.query.fetch("page", "1").to_i64?
    panic({{env}}, 400, "`page` must be an Int.") unless %pstart
    panic({{env}}, 400, "`size` must be an Int.") unless %psize
    panic({{env}}, 400, "`size` must be positive.") unless %psize > 0
    panic({{env}}, 400, "`page` must be positive.") unless %pstart > 0
    %start = (%pstart - 1) * %psize
  end

  %clause = in_range(%start, %psize)
  if {{order}}
    %clause = "ORDER BY datetime(date) DESC " + %clause
  end
  if {{filter}} != ""
    %clause = "WHERE #{ {{filter}} } " + %clause
  end

  %result = {{model}}.all(%clause)
  {{env}}.response.content_type = "application/json"
  %result.to_json
end

macro filtered_delete(env, model, filter)
  %clause = "WHERE #{ {{filter}} }"

  %deleted = 0
  %total = 0
  %last_error = ""
  %objs = {{model}}.all(%clause)
  %objs.each do |e|
    if e.destroy
      %deleted += 1
    else
      %last_error = e.errors[0]
    end
    %total += 1
  end

  panic({{env}}, 404, "No {{model}} matched filter.") if %total == 0
  panic({{env}}, 500, %last_error) if %total != %deleted
end

macro tidy_fields(attrs)
  {{attrs}}.each do |k, txt|
    {{attrs}}[k] = HTML.escape(txt.strip).gsub("\n", "<br />") if txt.is_a?(String)
  end
end
