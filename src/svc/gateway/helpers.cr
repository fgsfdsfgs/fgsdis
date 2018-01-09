require "json"
require "http/client"
require "uri"
require "html"
require "./client"

macro return_modified_body(env, r, e)
  {{env}}.response.status_code = {{r}}.status_code
  if %loc = {{r}}.headers["Location"]?
    {{env}}.response.headers["Location"] = %loc
  end
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{r}}.cookies.each do |c|
    {{env}}.response.cookies << c
  end
  {{env}}.response.print({{e}})
end

macro transform_response(env, r)
  {{env}}.response.status_code = {{r}}.status_code
  if %loc = {{r}}.headers["Location"]?
    {{env}}.response.headers["Location"] = %loc
  end
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{r}}.cookies.each do |c|
    {{env}}.response.cookies << c
  end
  {{env}}.response.print({{r}}.body)
end

macro transform_response_and_halt(env, r)
  {{env}}.response.status_code = {{r}}.status_code
  if %loc = {{r}}.headers["Location"]?
    {{env}}.response.headers["Location"] = %loc
  end
  if %ct = {{r}}.content_type
    {{env}}.response.content_type = %ct
  end
  {{r}}.cookies.each do |c|
    {{env}}.response.cookies << c
  end
  {{env}}.response.print({{r}}.body)
  return
end

macro pass_form(env, svc)
  %body = ""
  {{env}}.params.body.each do |k, v|
    %body += "#{k}=#{v}&"
  end
  %res = Client.request(
    {{svc}},
    {{env}}.request.method,
    {{env}}.request.resource,
    %body,
    "application/x-www-form-urlencoded"
  )
  transform_response({{env}}, %res)
end

macro pass_request(env, svc)
  %res = Client.request(
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
