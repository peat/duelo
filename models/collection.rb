class Collection

  def initialize( mongo_collection )
    @collection = mongo_collection
  end


  # adds a record to the collection
  def <<( record )
    @collection.insert( record )
    self.cleanup( record )
  end


  # retrieves a record by ID
  def []( record_id )
    record = self.find( 'id' => record_id ).first
    record = self.cleanup( record ) unless record.nil?
    record
  end


  # fetches a cursor for a query
  def find( query )
    @collection.find( query )
  end


  # removes a record from the collection
  def remove( id )
    @collection.remove( 'id' => id )
  end


  # checks to see if a record exists
  def exists?( id )
    self[id].nil? ? false : true
  end


  # saves the record
  def save( record )
    @collection.update( { 'id' => record['id'] }, record )
  end

  # counts the number of records in that collection
  def count
    @collection.count
  end


  protected


  def cleanup( record )
    record.delete(:_id)
    record
  end

end
