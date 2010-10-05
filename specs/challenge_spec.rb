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


  it "should respond correctly to a deny request" do

    charA = new_character
    charB = new_character
    skill = new_skill
    
    challenge = request(:post, "/challenge", { :from => charA['id'], :to => charB['id'], :skill => skill['id'] } )['challenge']

    health_before = health_request
    response = request(:post, "/deny", { :challenge => "#{challenge['id']}" } )
    health_after = health_request

    # check response 
    response['status'].should == 'OK'
    response['result']['status'].should == 'DENIED'
    response['result']['id'].should == challenge['id']

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


  it "should accept a challenge" do
    charA = new_character
    charB = new_character
    skillA = new_skill
    skillB = new_skill

    # create the challenge
    challenge = request(:post, "/challenge", { :from => charA['id'], :to => charB['id'], :skill => skillA['id'] } )['challenge']

    # accept the challenge
    history = request(:post, "/accept", { :challenge => challenge['id'], :skill => skillB['id'] } )

    history['status'].should == 'OK'
    [ charA['id'], charB['id'] ].should include( history['result']['winner'] )
    history['result']['id'].should == challenge['id']
    history['result']['from'].should == charA['id']
    history['result']['from_skill'].should == skillA['id']
    history['result']['to'].should == charB['id']
    history['result']['to_skill'].should == skillA['id']
  end


  it "should respond correctly to a history request" do
    charA = new_character
    charB = new_character
    skillA = new_skill
    skillB = new_skill

    # create the challenge
    challenge = request(:post, "/challenge", { :from => charA['id'], :to => charB['id'], :skill => skillA['id'] } )['challenge']

    # accept the challenge
    history = request(:post, "/accept", { :challenge => challenge['id'], :skill => skillB['id'] } )

    # go get the history for it
    response = request(:get, "/history", { :challenge => challenge['id'] } )

    response['status'].should == 'OK'

    # compare accept history with recorded history
    history.each do |k,v|
      response['history'][k].should == history['result'][k]
    end
  end

end
