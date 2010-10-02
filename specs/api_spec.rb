require './helper'

API_VERSION = 'v1'

describe "The API" do

  it "should respond correctly to a challenge request" do

    health_before = request("/health?key=key")
    response = request("/challenge?from=1234&to=6789&skill=abcd")
    health_after = request("/health?key=key")
    
    response['status'].should == "OK"
    response['challenge']['from'].should == "1234"
    response['challenge']['to'].should == "6789"
    response['challenge']['skill'].should == "abcd"
    response['challenge']['challenge'].length.should == 16

    # check health to make sure a record was inserted
    diff = 
      health_after['challenge_count'] - 
      health_before['challenge_count'] 

    diff.should == 1
  end

  it "should have the proper parameters for a challenge request" do
    response = request("/challenge")
    response['status'].should_not == "OK"
  end

  it "should respond correctly to a health request" do
    response = request("/health?key=key") 
    
    response['uptime'].should be_a( String )
    response['uptime'].length.should > 0
    response['character_count'].to_i.should be_an( Integer ) 
    response['challenge_count'].to_i.should be_an( Integer ) 
    response['history_count'].to_i.should be_an( Integer ) 
  end

  it "should require a key for a health request" do
    response = request("/health")
    response.should be_empty

    response = request("/health?key=notkey")
    response.should be_empty
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
