require './helper'

describe "The API" do

  it "should respond correctly to a health request" do
    response = health_request

    response['status'].should == "OK"
    response['uptime'].should be_a( String )
    response['uptime'].length.should > 0
    response['character_count'].to_i.should be_an( Integer ) 
    response['challenge_count'].to_i.should be_an( Integer ) 
    response['history_count'].to_i.should be_an( Integer ) 
    response['skills_count'].to_i.should be_an( Integer ) 
  end


  it "should require a key for a health request" do
    response = request(:get, "/health")
    response['status'].should == 'ERROR'

    response = request(:get, "/health", { :key => 'bad key' } )
    response['status'].should == 'ERROR'
  end

end
