require "./spec_helper"

describe FGSDis do
  it "returns 404 if route doesn't exist" do
    request = HTTP::Request.new("GET", "/__nothing")
    resp = test_request(request)
    resp.status_code.should eq 404
  end

  it "returns 200 or 304 if route exists" do
    request = HTTP::Request.new("GET", "/")
    resp = test_request(request)
    (resp.status_code == 200 || resp.status_code == 304).should be_true
  end
end
