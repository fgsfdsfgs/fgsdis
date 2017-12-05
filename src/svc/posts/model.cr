require "sqlite3"
require "granite_orm/adapter/sqlite"

module SPosts
  class Post < Granite::ORM::Base
    adapter sqlite
    table_name posts

    field user : Int64
    field title : String
    field text : String
    field date : String

    # belongs_to: :user
    # has_many: :comments

    validate :user, "is required", ->(this : Post) do
      if user = this.user
        user > 0
      else
        false
      end
    end

    validate :text, "is required", ->(this : Post) do
      this.text != nil && this.text != ""
    end

    validate :title, "is required", ->(this : Post) do
      this.title != nil && this.title != ""
    end

    SETTABLE_FIELDS = {"user", "title", "text"}
  end
end
