require "./spec_helper"
require "./fake_service"
require "../src/svc_gateway"

SGateway::Client.services = {
  :users    => "http://localhost:25666",
  :posts    => "http://localhost:25666",
  :comments => "http://localhost:25666",
}

mock = FakeService.new(25666)

describe SGateway do
  it "returns 404 if route doesn't exist" do
    get "/__nothing"
    response.status_code.should eq 404
  end

  it "returns 200 or 304 if route exists" do
    get "/"
    (response.status_code == 200 || response.status_code == 304).should be_true
  end

  it "returns responses from the echo server" do
    mock.push_response(200, "ass")
    get "/posts"
    response.status_code.should eq 200
    response.body.should eq "ass"
  end

  it "gets all posts" do
    mock.push_response(200, "not really posts")
    get "/posts"
    response.status_code.should eq 200
    response.body.should eq "not really posts"
  end

  it "adds username when getting posts by id" do
    mock.push_response(200, %({ "id": "1", "user": "2", "title": "test", "text": "ass" }), "application/json")
    mock.push_response(200, %({ "id": "2", "name": "John" }), "application/json")
    get "/post/1"
    mock.empty?.should be_true
    response.status_code.should eq 200
    response.body.should eq %({"id":"1","user":"2","title":"test","text":"ass","username":"John"})
  end

  it "gets comments on post" do
    mock.push_response(200, "not really comments")
    get "/post/1/comments"
    response.status_code.should eq 200
    response.body.should eq "not really comments"
  end

  it "updates posts" do
    mock.push_response(200, "$request")
    put_json "/post/1", %({ "text": "patchtext" })
    response.status_code.should eq 200
    response.body.should eq "PUT /post/1"
  end

  it "creates posts" do
    mock.push_response(200, "$request")
    post_json "/post", %({ "user": "1", "text": "ptext" })
    response.status_code.should eq 200
    response.body.should eq "POST /post"
  end

  it "creates comments and inserts post id from link" do
    mock.push_response(200, "$body")
    post_json "/post/1/comment", %({ "user": "1", "text": "ptext" })
    response.status_code.should eq 200
    response.body.should eq %({"user":"1","text":"ptext","post":"1"})
  end

  it "deletes posts and their comments" do
    mock.push_response(200, "$request")
    mock.push_response(200, "$request")
    delete "/post/1"
    response.status_code.should eq 200
    response.body.should eq "DELETE /post/1"
    mock.empty?.should be_true
  end

  it "gets users" do
    mock.push_response(200, "fake user")
    get "/user/1"
    response.status_code.should eq 200
    response.body.should eq "fake user"
  end

  it "gets a user's posts" do
    mock.push_response(200, "fake posts")
    get "/user/1/posts"
    response.status_code.should eq 200
    response.body.should eq "fake posts"
  end

  it "gets a user's comments" do
    mock.push_response(200, "fake comments")
    get "/user/1/comments"
    response.status_code.should eq 200
    response.body.should eq "fake comments"
  end

  it "gets a user's comments on a post" do
    mock.push_response(200, "fake comments 2")
    get "/user/1/post/1/comments"
    response.status_code.should eq 200
    response.body.should eq "fake comments 2"
  end

  it "updates users" do
    mock.push_response(200, "$request")
    put "/user/1", body: %({ "name": "editedname" })
    response.status_code.should eq 200
    response.body.should eq "PUT /user/1"
  end

  it "deletes users and their posts and comments" do
    mock.push_response(200, "$request")
    mock.push_response(200, "$request")
    mock.push_response(200, "$request")
    delete "/user/1"
    response.status_code.should eq 200
    response.body.should eq "DELETE /user/1"
    mock.empty?.should be_true
  end

  it "gets comments and adds usernames and post titles to them" do
    mock.push_response(200, %({ "user": "1", "post": "1", "text": "ass" }), "application/json")
    mock.push_response(200, %({ "id": "1", "name": "jack" }), "application/json")
    mock.push_response(200, %({ "id": "1", "title": "shitpost" }), "application/json")
    get "/comment/1"
    response.status_code.should eq 200
    response.body.should eq %({"user":"1","post":"1","text":"ass","username":"jack","posttitle":"shitpost"})
    mock.empty?.should be_true
  end

  it "deletes comments" do
    mock.push_response(200, "$request")
    delete "/comment/1"
    response.status_code.should eq 200
    response.body.should eq "DELETE /comment/1"
  end
end
