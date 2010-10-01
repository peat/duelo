require 'open-uri'
require 'json'

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
