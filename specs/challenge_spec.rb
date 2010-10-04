require './helper'

describe "The Challenge API" do

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

end
