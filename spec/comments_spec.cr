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

  it "doesn't post if not enough json data" do
    post "/comment", body: ""
    response.status_code.should eq 400
  end
end
