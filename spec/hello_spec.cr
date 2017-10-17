require "./spec_helper"

describe HelloPage do
  it "returns 200" do
    request = HTTP::Request.new("GET", "/hello")
    resp = test_request(request)
    resp.status_code.should eq 200
  end

  it "contains a greeting" do
    request = HTTP::Request.new("GET", "/hello")
    resp = test_request(request)
    flag = false
    HelloPage::GREETINGS.each do |g|
      flag ||= resp.body.includes?(g)
    end
    flag.should be_true
  end
end
