$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'uri'
require 'mongo'
require 'logger'
require 'json'

# mongo collection class
require 'collection'

class Duelo

  LOG = Logger.new( STDOUT )
  LOG.level = Logger::DEBUG

  KEYSPACE = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
  HEALTH_KEY = 'key' # CHANGE ME!!

  STATUS_NOT_FOUND = "NOT FOUND"
  STATUS_CREATED = "CREATED"
  STATUS_ERROR = "ERROR"
  STATUS_OK = "OK"

  def initialize
    db = Mongo::Connection.new.db('duelo')

    @characters = Collection.new( db['characters'] )
    @challenges = Collection.new( db['challenges'] )
    @history = Collection.new( db['history'] )
    @skills = Collection.new( db['skills'] )
  end

  # Method which Rack executes
  def call(env)
    start_time = Time.now
    
    request = Rack::Request.new(env)
    params = request.params # for convenience

    # hack for pattern matching!
    request_pattern = request_pattern_for( request )
    LOG.debug "Request: '#{request_pattern}' #{request.params.inspect}"
    
    response = case request_pattern
      when "get health"
        http_get_health( :key => params['key'] )
      when "get character"
        http_get_character( :character => params['character'] )
      when "post character"
        http_post_character( :name => params['name'] )
      when "put character"
        http_put_character( :character => params['character'], :skills => params['skills'] )
      when "post skill"
        http_post_skill( :name => params['name'] )
      when "post challenge"
        http_post_challenge( :from => params['from'], :to => params['to'], :skill => params['skill'] )
      when "post deny"
        http_post_deny( :challenge => params['challenge'] )
      when "post accept"
        http_post_accept( :challenge => params['challenge'], :skill => params['skill'] )
      when "get history"
        http_get_history( :challenge => params['challenge'] )
      else
        { :status => STATUS_ERROR, :uri => env['REQUEST_URI'], :error => "I don't know how to respond to a #{request.request_method.upcase} for #{request.path}." }
    end

    http_code = case response[:status]
      when STATUS_NOT_FOUND then 404
      when STATUS_ERROR then 400
      when STATUS_OK then 200
      else 500
    end

    end_time = Time.now

    # add processing time to response
    response[:time] = ((end_time - start_time) * 1000).ceil

    LOG.debug "Response: #{http_code} #{response.to_json}\n"

    [http_code, {'Content-Type' => 'application/json'}, response.to_json ]
  end

  def request_pattern_for( request )
    method = request.request_method.downcase
    # get the last element on the path
    resource = request.path.split("/").compact.last.downcase

    "#{method} #{resource}"
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
  def http_get_health( req )
    return { :status => STATUS_ERROR } if req[:key] != HEALTH_KEY

    {
      :status => STATUS_OK,
      :uptime => `uptime`.strip,
      :character_count => @characters.count,
      :challenge_count => @challenges.count,
      :skill_count => @skills.count,
      :history_count => @history.count
    }
  end


  # Retrieves a character.
  #
  # Expects:
  # 
  #   :character  should be a valid ID
  #
  # Returns
  #
  #   Hash object containing success code and 'character' record.
  #
  # Side effects:
  #
  #   None.
  #
  def http_get_character( req )
    # validates the name field has data.
    if req[:character].nil?
      return { :status => STATUS_ERROR, :error => "Gotta provide a character ID, holmes.", :request => req }
    end

    # find it
    character = @characters[ req[:character] ]

    if character.nil?
      return { :status => STATUS_NOT_FOUND, :error => "Couldn't find that character (#{req[:character]}).", :request => req }
    end

    { :status => STATUS_OK, :character => character }
  end

  # Creates a character.
  #
  # Expects:
  # 
  #   :name  should be a string.
  #
  # Returns
  #
  #   Hash object containing success code and 'character' record.
  #
  # Side effects:
  #
  #   Inserts a 'character' record.
  #
  def http_post_character( req )
    # validates the name field has data.
    if req[:name].nil?
      return { :status => STATUS_ERROR, :error => "Name required to create a character.", :request => req }
    end

    # create the character
    character = { 
      :id => generate_id,
      :name => req[:name],
      :skills => [], # no skills at creation
    }

    # stash it
    @characters << character

    character = @characters[ character[:id] ]

    { :status => STATUS_OK, :character => character }
  end

  # Updates a character.
  #
  # Expects:
  #
  #   :id       ID of the character to update
  #   :skills   Comma delimited list of skill IDs
  #
  # Returns
  #
  #   Hash object containing success code and the updated 'character' record.
  #
  # Side effects:
  #
  #   Updates the 'character' database
  #
  def http_put_character( req )

    # validate there is an ID present
    unless req[:character]
      return { :status => STATUS_ERROR, :error => "Please specify a character." }
    end

    # validate the ID maps to an existing record
    unless @characters.exists?( req[:character] )
      return { :status => STATUS_NOT_FOUND, :error => "Could not find character (#{req[:character]})" }
    end

    # extract the skills string
    if req[:skills]
      begin
        skills = req[:skills].split(',').collect { |s| s.strip }.uniq
      rescue => e
        return { :status => STATUS_ERROR, :error => "Expected a comma delimited string for skills (#{req[:skills]})" }
      end
    else
      skills = []
    end

    # verify those skills exist
    skills.each do |s|
      unless @skills.exists?( s )
        return { :status => STATUS_NOT_FOUND, :error => "Couldn't find skill (#{s}).", :request => req }
      end
    end

    character = @characters[ req[:character] ]
    character['skills'] = skills

    # update the character
    @characters.save( character )

    # return a canonical copy
    character = @characters[ req[:character] ]
    
    { :status => STATUS_OK, :character => character }
  end


  # Creates a skill.
  #
  # Expects:
  # 
  #   :name  should be a string.
  #
  # Returns
  #
  #   Hash object containing success code and 'skill' record.
  #
  # Side effects:
  #
  #   Inserts a 'skill' record.
  #
  def http_post_skill( req )
    # validates the name field has data.
    if req[:name].nil?
      return { :status => STATUS_ERROR, :error => "Name required to create a skill.", :request => req }
    end

    # create the skill
    skill = { 
      :id => generate_id,
      :name => req[:name]
    }

    # stash and clean it
    @skills << skill

    { :status => STATUS_OK, :skill => skill }
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
  def http_post_challenge( req )

    if !req[:from] or !req[:to] or !req[:skill]
      return { :status => STATUS_ERROR, :error => "You need to specify FROM, TO, and a SKILL in a challenge!", :request => req }
    end

    # Validate that 'from' does not equal 'to'
    if req[:from] == req[:to]
      return { :status => STATUS_ERROR, :error => "We do not support schizophrenic combat.", :request => req }
    end

    # Validate 'from' is a legitimate character
    unless @characters.exists?( req[:from] )
      return { :status => STATUS_NOT_FOUND, :error => "Unknown character ID (#{req[:from]}).", :request => req }
    end

    # Validate 'to' is a legitimate character
    unless @characters.exists?( req[:to] )
      return { :status => STATUS_NOT_FOUND, :error => "Unknown character ID (#{req[:to]}).", :request => req }
    end

    # Validate 'skill' is a legitimate skill, and owned by 'from' character
    unless @skills.exists?( req[:skill] )
      return { :status => STATUS_NOT_FOUND, :error => "Unknown skill ID (#{req[:skill]}).", :request => req }
    end

    unless character_has_skill?( req[:from], req[:skill] )
      return { :status => STATUS_NOT_FOUND, :error => "Character (#{req[:from]}) does not have skill (#{req[:skill]}).", :request => req }
    end

    # everything validates; create challenge!
    challenge = {
      :id => generate_id,
      :from => req[:from],
      :to => req[:to],
      :skill => req[:skill]
    }

    # stash in MongoDB
    @challenges << challenge

    # TODO: push notification into queue

    # respond with success message
    { :status => STATUS_OK, :challenge => challenge }
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
  def http_post_deny( req )
    # TODO: validate existance of 'challenge_id'

    # delete challenge from database
    challenge = @challenges[ req[:challenge] ]
    @challenges.remove( req[:challenge] )

    # create history record
    history = {
      :id => challenge['id'],
      :from => challenge['from'],
      :to => challenge['to'],
      :skill => challenge['skill'],
      :status => 'DENIED'
    }

    # insert history into database
    @history << history

    # TODO: push notifications for results

    # respond with success message
    { :status => STATUS_OK, :result => history }
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
  def http_post_accept( req )
    challenge = @challenges[ req[:challenge] ]

    unless challenge
      return { :status => STATUS_NOT_FOUND, :error => "Could not find challenge (#{req[:challenge]})." }
    end

    unless @skills.exists?( req[:skill] )
      return { :status => STATUS_NOT_FOUND, :error => "Could not find skill (#{req[:skill]})." }
    end

    unless character_has_skill?( challenge['to'], req[:skill] )
      return { :status => STATUS_ERROR, :error => "Character (#{req[:character]}) does not have skill (#{req[:skill]})." }
    end

    # passed all validations -- do or die!

    # delete challenge from database
    @challenges.remove( req[:challenge] )

    # do battle!
    winner = duel( challenge['from'], challenge['skill'], challenge['to'], req[:skill] )

    # create history record
    history = {
      'id' => challenge['id'],
      'from' => challenge['from'],
      'from_skill' => challenge['skill'],
      'to' => challenge['to'],
      'to_skill' => challenge['skill'],
      'winner' => winner,
      'status' => 'COMPLETED'
    }

    # insert history into database
    @history << history

    # TODO: push notifications for results

    # respond with success message
    { :status => STATUS_OK, :result => history }
  end


  # Retrieves a history record.
  #
  # Expects:
  #
  #   :challenge   should be a valid challenge ID
  #   
  # Returns:
  #
  #   Hash object containing success code and 'history' record.
  #
  # Side effects:
  #
  #   None
  #
  def http_get_history( req )

    history = @history[ req[:challenge] ]

    unless history
      return { :status => STATUS_NOT_FOUND, :error => "Could not find history (#{req[:challenge]})." }
    end

    { :status => STATUS_OK, :history => history }
  end


  protected


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

  
  def character_has_skill?( char_id, skill_id )
    true
  end

end
