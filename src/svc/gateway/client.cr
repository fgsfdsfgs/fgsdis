require "json"
require "http/client"
require "uri"

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

macro transform_response(env, r)
  puts({{env}}.request.resource)
  {{env}}.response.status_code = {{r}}.status_code
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{env}}.response.puts({{r}}.body)
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
