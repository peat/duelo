require './helper'

describe "The Session API" do

  it "should create a user" do
    health_before = health_request
    user = new_user
    health_after = health_request

    user['id'].length.should == 16
    user['login'].should_not be_nil
    user['password'].should be_nil
    user['salt'].should be_nil
    user['characters'].should be_empty

    diff = health_after['user_count'] - health_before['user_count']
    diff.should == 1
  end


  it "should create a token" do
    health_before = health_request
    response = request( :post, "/token", { :login => "test", :password => "test" } )
    health_after = health_request

    response['status'].should == 'OK'
    response['token'].length.should == 16
    response['user'].length.should == 16
  end



end
