require './helper'

API_VERSION = 'v1'

describe "The API" do

  it "should respond correctly to a challenge request" do
    response = request("/challenge?from=1234&to=6789&skill=abcd")
    
    response['status'].should == "OK"
    response['challenge']['from'].should == "1234"
    response['challenge']['to'].should == "6789"
    response['challenge']['skill'].should == "abcd"
    response['challenge']['challenge'].length.should == 16
  end

  it "should have the proper parameters for a challenge request" do
    response = request("/challenge")

    # empty request, needs parameters!
    response['status'].should_not == "OK"
  end

  def server
    ENV['SERVER'] || "http://localhost:8080"
  end

  def request( path )
    data = open("#{server}/#{API_VERSION}#{path}").read
    data.should be_json

    JSON.parse( data )
  end

end
