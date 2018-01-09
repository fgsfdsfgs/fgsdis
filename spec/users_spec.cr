require "./spec_helper"
require "../src/svc_users"

describe SUsers do
  it "returns 404 if route doesn't exist" do
    get "/__nothing"
    response.status_code.should eq 404
  end

  it "returns 200 or 304 if route exists" do
    get "/users"
    (response.status_code == 200 || response.status_code == 304).should be_true
  end

  it "doesn't post if not enough json data" do
    post "/user"
    response.status_code.should eq 400
  end

  it "doesn't post if json data is invalid" do
    post_json "/user", %({ "name": "", "email": "" })
    response.status_code.should eq 400
  end

  it "posts successfully if everything is good" do
    post_json "/user", %({ "name": "Ivan", "password": "abc", "email": "ivan@test.com" })
    response.status_code.should eq 201
  end

  it "doesn't get if entity id is invalid" do
    get "/user/ass"
    response.status_code.should eq 400
  end

  it "doesn't get if entity does not exist" do
    get "/user/666"
    response.status_code.should eq 404
  end

  it "gets successfully if entity exists" do
    get "/user/1"
    response.status_code.should eq 200
  end

  it "doesn't put if entity id is invalid" do
    put "/user/Ivan"
    response.status_code.should eq 400
  end

  it "doesn't put if entity doesn't exist" do
    put "/user/666"
    response.status_code.should eq 404
  end

  it "doesn't put if not enough json data" do
    put "/user/1"
    response.status_code.should eq 400
  end

  it "doesn't put if json data is invalid" do
    put_json "/user/1", %({ "email": "" })
    response.status_code.should eq 400
  end

  it "doesn't delete if entity id is invalid" do
    delete "/user/Ivan"
    response.status_code.should eq 400
  end

  it "doesn't delete if entity doesn't exist" do
    delete "/user/666"
    response.status_code.should eq 404
  end

  it "deletes successfully if entity exists" do
    delete "/user/1"
    response.status_code.should eq 200
  end
end
