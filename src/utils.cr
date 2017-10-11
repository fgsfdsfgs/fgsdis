require "kemal"

macro render_view(filename)
  render "src/views/#{{{filename}}}.ecr", "src/views/layouts/default.ecr"
end

macro render_view(filename, layout)
  render "src/views/#{{{filename}}}.ecr", "src/views/layouts/#{{{layout}}}.ecr"
end
