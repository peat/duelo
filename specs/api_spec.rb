require './helper'

describe "The API" do

  it "should respond correctly to a challenge request" do

    charA = new_character
    charB = new_character
    skill = new_skill

    health_before = health_request
    response = request(:post, "/challenge", 
      { 
        :from => charA['id'], 
        :to => charB['id'], 
        :skill => skill['id']
      }
    )
    health_after = health_request

    response['status'].should == "OK"
    response['challenge']['from'].should == charA['id']
    response['challenge']['to'].should == charB['id']
    response['challenge']['skill'].should == skill['id']
    response['challenge']['id'].length.should == 16

    # check health to make sure a record was inserted
    diff = 
      health_after['challenge_count'] - 
      health_before['challenge_count'] 

    diff.should == 1
  end


  it "should not allow a character to challenge themselves" do

    charA = new_character

    response = request(:post, "/challenge", 
      { 
        :from => charA['id'], 
        :to => charA['id'], 
        :skill => "abcd" 
      }
    )

    response['status'].should == "ERROR"
  end


  it "should have the proper parameters and method for a challenge request" do
    response = request(:get, "/challenge")
    response['status'].should == 'ERROR'

    response = request(:put, "/challenge")
    response['status'].should == 'ERROR'

    response = request(:post, "/challenge")
    response['status'].should == 'ERROR'
  end


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
