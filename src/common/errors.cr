require "kemal"

error 400 do
  "400: Bad request."
end

error 404 do
  "404: Page not found."
end

error 401 do
  "403: Unauthorized."
end

error 403 do
  "403: Forbidden."
end

error 500 do
  "500: Internal server error."
end
