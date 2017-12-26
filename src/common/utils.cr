require "openssl"
require "http/server"
require "kemal"

ROOT_DIR = "."

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

def sha256(x) : String
  d = OpenSSL::Digest.new("SHA256")
  d.update(x)
  d.hexdigest
end
