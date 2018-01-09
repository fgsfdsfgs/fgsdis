require "json"
require "kemal"
require "html"

macro oauth_panic(env, redir, error, detail = nil)
  if {{detail}}
    {{detail}} = HTML.escape({{detail}})
    {{env}}.redirect({{redir}} + "?error=#{ {{error}} }&error_description=#{ {{detail}} }")
  else
    {{env}}.redirect({{redir}} + "?error=#{ {{error}} }")
  end
  return
end
