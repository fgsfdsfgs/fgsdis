require "json"
require "http/client"
require "uri"

alias Entity = Hash(String, JSON::Type)

SERVICES = {
  :users    => CONFIG_SVC_USERS_ADDR,
  :posts    => CONFIG_SVC_POSTS_ADDR,
  :comments => CONFIG_SVC_COMMENTS_ADDR,
}

def svc(svname, method, uri, body = nil, mime = "application/json")
  if sv = SERVICES[svname]
    hdr = HTTP::Headers.new
    hdr["Content-Type"] = mime
    HTTP::Client.exec(method, "#{sv}#{uri}", body: body, headers: hdr)
  else
    HTTP::Client::Response.new(500)
  end
end

def get_entity(res) : Entity | Nil
  if res.status_code == 200 && res.content_type == "application/json"
    begin
      ent = {} of String => JSON::Type

      case json = JSON.parse(res.body).raw
      when Hash
        json.each do |k, v|
          ent[k] = v.as(JSON::Type)
        end
      when Array
        ent["_json"] = json
      end

      return ent
    rescue
      return nil
    end
  else
    return nil
  end
end

def svc_get_entity(svname, uri) : Tuple(HTTP::Client::Response, Entity | Nil)
  res = svc(svname, "GET", uri)
  {res, get_entity(res)}
end

macro return_modified_body(env, r, e)
  puts({{env}}.request.resource)
  {{env}}.response.status_code = {{r}}.status_code
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{env}}.response.print({{e}})
end

macro transform_response(env, r)
  puts({{env}}.request.resource)
  {{env}}.response.status_code = {{r}}.status_code
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{env}}.response.print({{r}}.body)
end

macro transform_response_and_halt(env, r)
  puts({{env}}.request.resource)
  {{env}}.response.status_code = {{r}}.status_code
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{env}}.response.print({{r}}.body)
  next
end

macro pass_request(env, svc)
  puts({{env}}.request.resource)
  %res = svc(
    {{svc}},
    {{env}}.request.method,
    {{env}}.request.resource,
    {{env}}.request.body
  )
  transform_response({{env}}, %res)
end

macro copy_pagination_params(env, req)
  if %page = {{env}}.params.query["page"]?
    {{req}} += "?page=#{%page}"
    if %size = {{env}}.params.query["size"]?
      {{req}} += "&size=#{%size}"
    end
  end
end
