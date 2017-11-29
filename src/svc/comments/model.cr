require "sqlite3"
require "granite_orm/adapter/sqlite"

module SComments
  class Comment < Granite::ORM::Base
    adapter sqlite
    table_name comments

    field user : Int64
    field post : Int64
    field date : String
    field text : String

    # belongs_to: :user
    # belongs_to: :post

    validate :user, "is required", ->(this : Comment) do
      if user = this.user
        user > 0
      else
        false
      end
    end

    validate :post, "is required", ->(this : Comment) do
      if post = this.post
        post > 0
      else
        false
      end
    end

    validate :text, "is required", ->(this : Comment) do
      this.text != nil && this.text != ""
    end

    SETTABLE_FIELDS = {"user", "post", "text"}
  end
end
