require "sqlite3"
require "granite_orm/adapter/sqlite"

module SUsers
  class User < Granite::ORM::Base
    adapter sqlite
    table_name users

    field email : String
    field name : String
    field description : String
    field reg_date : String

    # has_many: :posts
    # has_many: :comments

    validate :email, "is required", ->(this : User) do
      this.email != nil && this.email != ""
    end

    validate :name, "is required", ->(this : User) do
      this.name != nil && this.name != ""
    end

    CREATE_FIELDS = {"email", "name", "description"}
    EDIT_FIELDS   = {"description"}
  end
end
