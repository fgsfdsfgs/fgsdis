require "kemal"

error 400 do
  "400: Bad Request"
end

error 404 do
  "404: Not Found"
end

error 403 do
  "403: Forbidden"
end

error 500 do
  "500: Internal Server Error"
end
