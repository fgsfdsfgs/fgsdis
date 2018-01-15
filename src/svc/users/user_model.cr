require "sqlite3"
require "granite_orm/adapter/sqlite"

module SUsers
  class User < Granite::ORM::Base
    adapter sqlite
    table_name users

    field email : String
    field password : String
    field name : String
    field description : String
    field reg_date : String
    field role : String

    # has_many :posts
    # has_many :comments
    has_many :tokens
    has_many :codes

    validate :email, "is required", ->(this : User) do
      this.email != nil && this.email != ""
    end

    validate :password, "is required", ->(this : User) do
      this.password != nil && this.password != ""
    end

    validate :name, "is required", ->(this : User) do
      this.name != nil && this.name != ""
    end

    validate :role, "is required", ->(this : User) do
      this.role != nil && this.role != ""
    end

    CREATE_FIELDS = {"email", "name", "description", "password"}
    EDIT_FIELDS   = {"description"}
  end
end
