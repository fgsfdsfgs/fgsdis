require "./spec_helper"

describe RootPage do
  it "returns 200" do
    request = HTTP::Request.new("GET", "/")
    resp = test_request(request)
    resp.status_code.should eq 200
  end

  it "contains the words TEST PAGE" do
    request = HTTP::Request.new("GET", "/")
    resp = test_request(request)
    resp.body.should contain "TEST PAGE"
  end
end
