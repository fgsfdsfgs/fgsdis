require "./spec_helper"
require "../src/svc_comments"

describe SComments do
  it "returns 404 if route doesn't exist" do
    get "/__nothing"
    response.status_code.should eq 404
  end

  it "returns 200 or 304 if route exists" do
    get "/comments"
    (response.status_code == 200 || response.status_code == 304).should be_true
  end

  it "errors if pagination parameters are invalid" do
    get "/comments/by_user/1?page=a&size=b"
    response.status_code.should eq 400
    get "/comments/by_post/1?page=a&size=b"
    response.status_code.should eq 400
    get "/comments/by_user/1/by_post/1?page=a&size=b"
    response.status_code.should eq 400
  end

  it "filters by post with pagination" do
    get "/comments/by_post/1?page=1&size=10"
    response.status_code.should eq 200

    post_json "/comment", %({ "user": "1", "post": "1", "text": "text11" })
    post_json "/comment", %({ "user": "2", "post": "1", "text": "text21" })

    get "/comments/by_post/1?page=1&size=2"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2

    get "/comments/by_post/1?page=1&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text11"))

    get "/comments/by_post/1?page=2&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text21"))

    get "/comments/by_post/1?page=22&size=11"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    delete "/comment/1"
    delete "/comment/2"
  end

  it "filters by user with pagination" do
    get "/comments/by_user/1?page=1&size=10"
    response.status_code.should eq 200

    post_json "/comment", %({ "user": "1", "post": "1", "text": "text11" })
    post_json "/comment", %({ "user": "1", "post": "2", "text": "text12" })

    get "/comments/by_user/1?page=1&size=2"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2

    get "/comments/by_user/1?page=1&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text11"))

    get "/comments/by_user/1?page=2&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text12"))

    get "/comments/by_user/1?page=22&size=11"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    delete "/comment/1"
    delete "/comment/2"
  end

  it "filters by user and post with pagination" do
    get "/comments/by_user/1/by_post/1?page=1&size=10"
    response.status_code.should eq 200

    post_json "/comment", %({ "user": "1", "post": "1", "text": "text11" })
    post_json "/comment", %({ "user": "1", "post": "1", "text": "text111" })
    post_json "/comment", %({ "user": "2", "post": "2", "text": "text21" })

    get "/comments/by_user/1/by_post/1?page=1&size=2"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2

    get "/comments/by_user/1/by_post/1?page=1&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text11"))

    get "/comments/by_user/1/by_post/1?page=2&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("text111"))

    get "/comments/by_user/1/by_post/1?page=22&size=11"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    get "/comments/by_user/1/by_post/2?page=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    get "/comments/by_user/2/by_post/1?page=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    delete "/comment/1"
    delete "/comment/2"
    delete "/comment/3"
  end

  it "doesn't filter by user if user id is invalid" do
    get "/comments/by_user/ass"
    response.status_code.should eq 400
  end

  it "doesn't filter by post if post id is invalid" do
    get "/comments/by_post/ass"
    response.status_code.should eq 400
  end

  it "doesn't filter by user and post if post or user id is invalid" do
    get "/comments/by_user/1/by_post/ass"
    response.status_code.should eq 400
    get "/comments/by_user/ass/by_post/1"
    response.status_code.should eq 400
    get "/comments/by_user/ass/by_post/ass"
    response.status_code.should eq 400
  end

  it "doesn't post if not enough json data" do
    post "/comment", body: ""
    response.status_code.should eq 400
  end

  it "doesn't post if json data is invalid" do
    post_json "/comment", %({ "user": "0", "post": "0", "text": "" })
    response.status_code.should eq 400
  end

  it "posts successfully if everything is good" do
    post_json "/comment", %({ "user": "1", "post": "1", "text": "text" })
    response.status_code.should eq 201
  end

  it "doesn't get if entity id is invalid" do
    get "/comment/ass"
    response.status_code.should eq 400
  end

  it "doesn't get if entity does not exist" do
    get "/comment/666"
    response.status_code.should eq 404
  end

  it "gets successfully if entity exists" do
    get "/comment/1"
    response.status_code.should eq 200
  end

  it "doesn't delete if entity id is invalid" do
    delete "/comment/Ivan"
    response.status_code.should eq 400
  end

  it "doesn't delete if entity doesn't exist" do
    delete "/comment/666"
    response.status_code.should eq 404
  end

  it "deletes successfully if entity exists" do
    delete "/comment/1"
    response.status_code.should eq 200
  end

  it "doesn't delete by user if user has no comments" do
    post_json "/comment", %({ "user": "3", "post": "3", "text": "text" })
    post_json "/comment", %({ "user": "3", "post": "4", "text": "text2" })
    delete "/comments/by_user/666"
    response.status_code.should eq 404

    get "/comments/by_user/3"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2
  end

  it "deletes by user successfully if user has comments" do
    delete "/comments/by_user/3"
    response.status_code.should eq 200

    get "/comments/by_user/3"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0
  end

  it "doesn't delete by post if post has no comments" do
    post_json "/comment", %({ "user": "4", "post": "5", "text": "text" })
    post_json "/comment", %({ "user": "5", "post": "5", "text": "text2" })
    delete "/comments/by_post/666"
    response.status_code.should eq 404

    get "/comments/by_post/5"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2
  end

  it "deletes by post successfully if post has comments" do
    delete "/comments/by_post/5"
    response.status_code.should eq 200

    get "/comments/by_post/5"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0
  end
end
