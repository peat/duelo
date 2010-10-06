require 'net/http'
require 'uri'
require 'json'

API_VERSION = 'v1'

RSpec::Matchers.define :be_json do
  match do |actual|
    begin
      JSON.parse( actual )
      true
    rescue => e
      false
    end
  end
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

def new_user
  user = request( :post, "/user", { :login => "user#{rand}", :password => 'password' } )['user']
  user.should_not be_nil
  user
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

