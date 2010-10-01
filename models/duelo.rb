require 'rubygems'
require 'uri'
require 'mongo'
require 'logger'
require 'json'

class Duelo

  LOG = Logger.new( STDOUT )
  LOG.level = Logger::DEBUG

  KEYSPACE = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
  HEALTH_KEY = 'key' # CHANGE ME!!

  def initialize
    @db_connection = Mongo::Connection.new.db('duelo')
    @characters = @db_connection['characters'] 
    @challenges = @db_connection['challenges']
    @history = @db_connection['history'] 
  end

  # Method which Rack executes
  def call(env)
    request = parse_request_uri( env['REQUEST_URI'] )
    LOG.debug "REQUEST: #{request.inspect}"

    response = case request[:action]
      when "health"
        do_health( :key => request[:key] )
      when "challenge"
        do_challenge( :from => request[:from], :to => request[:to], :skill => request[:skill] )
      when "deny"
        do_deny( :challenge => request[:challenge] )
      else
        # ruh oh, don't recognize the action! return an error and debugging information.
        { :status => 'ERROR', :uri => env['REQUEST_URI'], :request => request, :error => "Unknown 'action' #{request[:action]}" }
    end

    [200, {'Content-Type' => 'application/json'}, response.to_json ]
  end

  def parse_request_uri( uri )
    request_uri = URI.parse( uri )

    path = request_uri.path.split('/')
    query = Rack::Utils.parse_query( request_uri.query )

    out = {}
    out[:version] = path[1]
    out[:action] = path[2]

    query.each { |k,v| out[k.to_sym] = v }

    out
  end

  # Returns health stats for the system.
  #
  # Expects:
  #
  #   :key    should be the password key
  #
  # Returns:
  #
  #   Hash object containing vital stats.
  #
  # Side effects:
  #
  #   None.
  #
  def do_health( req )
    return {} if req[:key] != HEALTH_KEY
    {
      :uptime => `uptime`,
      :character_count => @characters.count,
      :challenge_count => @challenges.count,
      :history_count => @history.count
    }
  end


  # Creates a challenge request.
  #
  # Expects:
  #
  #   :from   should be a valid character ID
  #   :to     should be a valid character ID
  #   :skill  should be a valid skill owned by :from character
  #
  # Returns:
  # 
  #   Hash object containing success code and 'challenge' record.
  #
  # Side effects:
  #
  #   Inserts a 'challenge' record into the database.
  #   Inserts a notification of the challenge into the push queue.
  #   Sends push notifications to 'to' person.
  #
  def do_challenge( req )

    # TODO: validate 'from' is a legitimate character
    # TODO: validate 'to' is a legitimate character
    # TODO: validate 'skill' is a legitimate skill owned by 'from' character

    # everything validates; create challenge!
    challenge = {
      :challenge => generate_id,
      :from => req[:from],
      :to => req[:to],
      :skill => req[:skill]
    }

    # stash in MongoDB
    @challenges.insert( challenge )
    challenge.delete(:_id) # insert will modify the object; stupid!

    # TODO: push notification into queue

    # respond with success message
    { :status => 'OK', :challenge => challenge }
  end


  # Denies a challenge request.
  #
  # Expects:
  #
  #   :challenge  should be a valid challenge ID
  #   
  # Returns:
  #
  #   Hash object containing success code and 'history' record.
  #
  # Side effects:
  #
  #   Deletes a 'challenge' record from the database.
  #   Inserts a 'history' record into the database.
  #   Sends push notifications to both duelers.
  #
  def do_deny( req )
    # TODO: validate existance of 'challenge_id'

    # delete challenge from database
    query = { :challenge => req[:challenge] }
    challenge = @challenges.find( query ).first
    @challenges.remove( query )

    # create history record
    history = {
      :challenge => req[:challenge],
      :status => 'DENIED'
    }

    # insert history into database
    @history.insert( history )
    history.delete(:_id) # insert modifies object; stupid!

    # TODO: push notifications for results

    # respond with success message
    { :status => 'OK', :result => history }
  end
  

  # Accepts a challenge request.
  #
  # Expects:
  #
  #   :challenge_id   should be a valid challenge ID
  #   :skill          should be a valid skill ID owned by 'to' character in challenge
  #   
  # Returns:
  #
  #   Hash object containing success code and 'history' record.
  #
  # Side effects:
  #
  #   Deletes a 'challenge' record from the database.
  #   Inserts a 'history' record into the database.
  #   Sends push notifications to both duelers.
  #
  def do_accept( req )
    # TODO: validate existance of 'challenge_id'

    # delete challenge from database
    query = { "challenge_id" => req[:challenge_id] }
    challenge = @challenges.find( query )
    @challenges.remove( query )

    # do battle!
    winner = duel( challenge['from'], challenge['skill'], challenge['to'], req['skill'] )

    # create history record
    history = {
      'challenge' => challenge,
      'winner' => winner
    }

    # insert history into database
    @history.insert( history )

    # TODO: push notifications for results

    # respond with success message
    { :status => 'OK', :result => history }
  end

  def generate_id
    out = ""
    16.times do |i|
      out << KEYSPACE[ rand( KEYSPACE.length ) ]
    end
    out
  end

  def duel( from, from_skill, to, to_skill )
    case rand(2)
      when 0 then from
      else to
    end
  end
  
end
