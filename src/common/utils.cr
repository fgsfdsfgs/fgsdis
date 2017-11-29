require "kemal"

ROOT_DIR = "."

macro render_view(filename)
  render("src/views/#{ {{filename}} }.ecr", "src/views/layouts/default.ecr")
end

macro render_view(filename, layout)
  render("src/views/#{ {{filename}} }.ecr", "src/views/layouts/#{ {{layout}} }.ecr")
end

def in_range(offset = 0, size = 1)
  if size == 0
    ""
  else
    "LIMIT #{size} OFFSET #{offset}"
  end
end

def with_field(field, value)
  "WHERE #{field} = #{value}"
end
