require './helper'

describe "The API" do

  it "should respond correctly to a deny request" do
    
    challenge = request(:post, "/challenge", { :from => 1234, :to => 6789, :skill => "abcd" } )['challenge']

    health_before = health_request
    response = request(:post, "/deny", { :challenge => "#{challenge['id']}" } )
    health_after = health_request

    # check response 
    response['status'].should == 'OK'
    response['result']['status'].should == 'DENIED'
    response['result']['challenge'].should == challenge['challenge']

    # check history
    challenge_diff =
      health_after['challenge_count'] - 
      health_before['challenge_count'] 

    history_diff =
      health_after['history_count'] - 
      health_before['history_count'] 

    challenge_diff.should == -1
    history_diff.should == 1
  end


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
