require './helper'

describe "The Character API" do

  it "should create a character" do
    health_before = health_request
    response = request( :post, "/character", { :name => "Peat's Mage" } )
    health_after = health_request

    response['status'].should == 'OK'
    response['character']['id'].length.should == 16
    response['character']['name'].should == "Peat's Mage"
    response['character']['skills'].should be_empty
  end


  it "should get a character" do
    c = new_character

    response = request( :get, "/character", { :character => c['id'] } )

    response['character']['id'].should == c['id']
  end


  it "should update a character" do
    c = new_character
    s = new_skill

    params = {
      :character => c['id'],
      :skills => [ s['id'] ].join(',')
    }

    response = request( :put, "/character", params )

    response['status'].should == 'OK'
    response['character']['skills'].should include( s['id'] )
  end


  it "should not allow you to change a character's name" do
    c = new_character
    bad_name = "Jimmy Bob"

    params = { :character => c['id'], :name => bad_name }

    response = request( :put, "/character", params )

    response['status'].should == 'OK'
    response['character']['name'].should_not == bad_name
  end


  it "should allow mulitple skills for a character" do
    c = new_character
    sA = new_skill
    sB = new_skill

    params = { :character => c['id'], :skills => [ sA['id'], sB['id'] ].join(',') }

    response = request( :put, "/character", params )

    response['status'].should == 'OK'
    response['character']['skills'].should include( sA['id'] )
    response['character']['skills'].should include( sB['id'] )
    response['character']['skills'].length.should == 2

  end


  it "should not allow duplicate skills for a character" do
    c = new_character
    s = new_skill

    params = { :character => c['id'], :skills => [ s['id'], s['id'], s['id'] ].join(',') }

    response = request( :put, "/character", params )

    response['status'].should == 'OK'
    response['character']['skills'].should include( s['id'] )
    response['character']['skills'].length.should == 1
  end


  it "should not allow skills that don't exist to be added to a character" do
    c = new_character

    params = {
      :character => c['id'],
      :skills => 'non-existant-id'
    }

    response = request( :put, "/character", params )

    response['status'].should == 'NOT FOUND'
  end

end
