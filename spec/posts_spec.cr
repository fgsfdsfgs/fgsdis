require "./spec_helper"
require "../src/svc_posts"

describe SPosts do
  it "returns 404 if route doesn't exist" do
    get "/__nothing"
    response.status_code.should eq 404
  end

  it "returns 200 or 304 if route exists" do
    get "/posts"
    (response.status_code == 200 || response.status_code == 304).should be_true
  end

  it "errors if pagination parameters are invalid" do
    get "/posts?page=a&size=b"
    response.status_code.should eq 400
  end

  it "does pagination" do
    get "/posts?page=1&size=10"
    response.status_code.should eq 200

    post_json "/post", %({ "user": "1", "title": "title1", "text": "text1" })
    post_json "/post", %({ "user": "2", "title": "title2", "text": "text2" })

    get "/posts?page=1&size=2"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2

    get "/posts?page=1&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("title1"))

    get "/posts?page=2&size=1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain(%("title2"))

    get "/posts?page=22&size=11"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    delete "/post/1"
    delete "/post/2"
  end

  it "doesn't post if not enough json data" do
    post "/post"
    response.status_code.should eq 400
  end

  it "doesn't post if json data is invalid" do
    post_json "/post", %({ "user": "0", "title": "", "text": "" })
    response.status_code.should eq 400
  end

  it "posts successfully if everything is good" do
    post_json "/post", %({ "user": "1", "title": "title", "text": "text" })
    response.status_code.should eq 200
  end

  it "doesn't get if entity id is invalid" do
    get "/post/ass"
    response.status_code.should eq 400
  end

  it "doesn't get if entity does not exist" do
    get "/post/666"
    response.status_code.should eq 404
  end

  it "gets successfully if entity exists" do
    get "/post/1"
    response.status_code.should eq 200
  end

  it "doesn't put if entity id is invalid" do
    put "/post/Ivan"
    response.status_code.should eq 400
  end

  it "doesn't put if entity doesn't exist" do
    put "/post/666"
    response.status_code.should eq 404
  end

  it "doesn't put if not enough json data" do
    put "/post/1"
    response.status_code.should eq 400
  end

  it "doesn't put if json data is invalid" do
    put_json "/post/1", %({ "title": "" })
    response.status_code.should eq 400
  end

  it "doesn't delete if entity id is invalid" do
    delete "/post/Ivan"
    response.status_code.should eq 400
  end

  it "doesn't delete if entity doesn't exist" do
    delete "/post/666"
    response.status_code.should eq 404
  end

  it "deletes successfully if entity exists" do
    delete "/post/1"
    response.status_code.should eq 200
  end

  it "doesn't delete by user if user has no posts" do
    post_json "/post", %({ "user": "3", "title": "title", "text": "text" })
    post_json "/post", %({ "user": "3", "title": "title2", "text": "text2" })
    delete "/posts/by_user/666"
    response.status_code.should eq 404

    get "/posts/by_user/3"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 2
  end

  it "deletes by user successfully if user has posts" do
    delete "/posts/by_user/3"
    response.status_code.should eq 200

    get "/posts/by_user/3"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0
  end

  it "doesn't filter by user if user id is invalid" do
    get "/posts/by_user/ass"
    response.status_code.should eq 400
  end

  it "filters by user id with pagination" do
    post_json "/post", %({ "user": "1", "title": "title1", "text": "text1" })
    post_json "/post", %({ "user": "2", "title": "title2", "text": "text2" })

    get "/posts/by_user/1"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain("title1")

    get "/posts/by_user/2"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain("title2")

    get "/posts/by_user/666"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    get "/posts/by_user/1?page=1&size=666"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain("title1")

    get "/posts/by_user/2?page=1&size=666"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 1
    response.body.should contain("title2")

    get "/posts/by_user/2?page=3&size=666"
    response.status_code.should eq 200
    json = JSON.parse(response.body)
    json.raw.should be_a(Array(JSON::Type))
    json.as_a.size.should eq 0

    delete "/post/1"
    delete "/post/2"
  end
end
