require "openssl"
require "json"

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

def parse_json?(body)
  begin
    json = JSON.parse(body)
  rescue
    json = nil
  end
  json
end

def json_to_hash?(json)
  begin
    ent = {} of String => JSON::Type

    case json = JSON.parse(json).raw
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
end
