require "json"
require "time"
require "../../common/helpers"
require "../../common/utils"
require "./config"
require "./client"
require "./helpers"
require "./auth"
require "./request_queue"
require "kemal"

module SGateway
  module ApiController
    # /post

    def self.get_all_posts(env)
      pass_request(env, :posts)
    end

    def self.get_post(env)
      pid = env.params.url["id"]

      res, post = Client.get_entity(:posts, "/post/#{pid}")
      transform_response_and_halt(env, res) unless post

      res_u, user = Client.get_entity(:users, "/user/#{post["user"]}")

      post["username"] = user["name"] if user
      new_body = post.to_json
      return_modified_body(env, res, new_body)
    end

    def self.get_comments_on_post(env)
      pid = env.params.url["id"]
      request = "/comments/by_post/#{pid}"
      copy_pagination_params(env, request)
      res = Client.request(:comments, "GET", request)
      transform_response(env, res)
    end

    def self.create_post(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      validate_login_or_halt(env, info)

      body = env.params.json.to_json
      res = Client.request(:posts, "POST", "/post", body)
      transform_response(env, res)
    end

    def self.create_comment_on_post(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      validate_login_or_halt(env, info)

      if !env.params.json.has_key?("post")
        env.params.json["post"] = env.params.url["id"]
      end

      body = env.params.json.to_json
      res = Client.request(:comments, "POST", "/comment", body)
      transform_response_and_halt(env, res) unless res.status_code == 201

      req = "/post/#{env.params.json["post"]}"
      rating = env.params.json.fetch("rating", "0")
      res_p = Client.request(:posts, "PATCH", req, %({ "rating": "#{rating}" }))
      transform_response_and_halt(env, res) if res_p.status_code == 200

      # rollback
      res_d = Client.request(:comments, "DELETE", "#{res.headers["Location"]}")
      transform_response(env, res_p)
    end

    def self.update_post(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      user = OAuth.get_authorized_user(env, info)

      pid = env.params.url["id"]
      res, post = Client.get_entity(:posts, "/post/#{pid}")
      transform_response_and_halt(env, res) unless post
      if user != "0" && user != post["user"].to_s
        panic(env, 403, "You can only edit your own posts.")
      end

      pass_request(env, :posts)
    end

    def self.delete_post(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      user = OAuth.get_authorized_user(env, info)

      pid = env.params.url["id"]
      res, post = Client.get_entity(:posts, "/post/#{pid}")
      transform_response_and_halt(env, res) unless post
      if user != "0" && user != post["user"].to_s
        panic(env, 403, "You can only delete your own posts.")
      end

      res_c = Client.queue_request(:comments, "DELETE", "/comments/by_post/#{pid}")
      res_p = Client.queue_request(:posts, "DELETE", "/post/#{pid}")
      if res_c.status_code == 202
        transform_response(env, res_c)
      else
        transform_response(env, res_p)
      end
    end

    # /user

    def self.get_user(env)
      pass_request(env, :users)
    end

    def self.get_posts_by_user(env)
      uid = env.params.url["id"]
      request = "/posts/by_user/#{uid}"
      copy_pagination_params(env, request)
      res = Client.request(:posts, "GET", request)
      transform_response(env, res)
    end

    def self.get_comments_by_user(env)
      uid = env.params.url["id"]
      request = "/comments/by_user/#{uid}"
      copy_pagination_params(env, request)
      res = Client.request(:comments, "GET", request)
      transform_response(env, res)
    end

    def self.get_comments_by_user_on_post(env)
      uid = env.params.url["id"]
      pid = env.params.url["pid"]
      res = Client.request(:comments, "GET", "/comments/by_user/#{uid}/by_post/#{pid}")
      transform_response(env, res)
    end

    def self.update_user(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      validate_login_or_halt(env, info)

      pass_request(env, :users)
    end

    # /comment

    def self.get_comment(env)
      cid = env.params.url["id"]

      res, com = Client.get_entity(:comments, "/comment/#{cid}")
      transform_response_and_halt(env, res) unless com

      res_u, user = Client.get_entity(:users, "/user/#{com["user"]}")
      res_p, post = Client.get_entity(:posts, "/post/#{com["post"]}")

      com["username"] = user["name"] if user
      com["posttitle"] = post["title"] if post
      new_body = com.to_json
      return_modified_body(env, res, new_body)
    end

    def self.delete_comment(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      user = OAuth.get_authorized_user(env, info)

      cid = env.params.url["id"]

      res, com = Client.get_entity(:comments, "/comment/#{cid}")
      transform_response_and_halt(env, res) unless com
      if user != "0" && user != com["user"].to_s
        panic(env, 403, "You can only delete your own comments.")
      end

      rating = com["rating"].to_s.to_i64?
      if rating && rating != 0
        req = "/post/#{com["post"]}"
        res_p = Client.request(:posts, "PATCH", req, %({ "rating": "#{-rating}" }))
        transform_response_and_halt(env, res_p) if res_p.status_code > 399
      end

      pass_request(env, :comments)
    end

    # /stats

    def self.get_stats_report(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      validate_role_or_halt(env, info, "admin")

      pass_request(env, :stats)
    end

    def self.get_all_stats_reports(env)
      token, info = OAuth.get_auth_info(env)
      validate_token_or_halt(env, token, info)
      validate_role_or_halt(env, info, "admin")

      pass_request(env, :stats)
    end
  end
end
