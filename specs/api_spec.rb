require './helper'

API_VERSION = 'v1'

describe "The API" do

  it "should create a character" do
    health_before = health_request
    response = request( :post, "/character", { :name => "Peat's Mage" } )
    health_after = health_request

    response['status'].should == 'OK'
    response['character']['id'].length.should == 16
    response['character']['name'].should == "Peat's Mage"
    response['character']['skills'].should be_empty
  end


  it "should update a character" do
    c = new_character
    s = new_skill

    params = {
      :character => c['id'],
      :skills => [ s['id'] ]
    }

    response = request( :put, "/character", params )

    response['status'].should == 'OK'
    response['character']['skills'].should include( s['id'] )
  end

  it "should not allow you to change a character's name"

  it "should not allow duplicate skills for a character"

  it "should not allow skills that don't exist to be added to a character"


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


  def server
    ENV['SERVER'] || "http://localhost:8080"
  end


  def request( http_method, path, query = {} )
    url = URI.parse("#{server}/v1#{path}")

    # hack for query parameter in GETs
    if http_method == :get
      if query.empty?
        get_path = url.path
      else
        query_array = []
        query.each do |k,v|
          query_array << "#{URI.escape( k.to_s )}=#{URI.escape( v.to_s )}"
        end
        get_path = url.path + "?" + query_array.join("&");
      end
    end

    req = case http_method
      when :get then Net::HTTP::Get.new( get_path )
      when :put then Net::HTTP::Put.new( url.path )
      when :post then Net::HTTP::Post.new( url.path )
      when :delete then Net::HTTP::Delete.new( url.path )
    end

    res = Net::HTTP.start( url.host, url.port ) { |http|
      req.set_form_data( query ) if http_method != :get
      http.request( req )
    }

    JSON.parse( res.body )
  end


  def new_character
    character = request( :post, "/character", { :name => "Valid Character" } )['character']
    character.should_not be_nil
    character
  end


  def new_skill
    skill = request( :post, "/skill", { :name => "Valid Skill" } )['skill']
    skill.should_not be_nil
    skill
  end


  def health_request
    request(:get, "/health", { :key => 'key' } )
  end

end
