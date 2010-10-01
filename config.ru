# The 'rackup' file config.

# environment dependencies
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] # hack for passenger
require 'rubygems'
require 'rack'

# the app
require './models/duelo'

# Sets content-length header to whatever
# we're going to pass...in our case, 0.
use Rack::ContentLength

STDOUT.reopen('production.log')

run Duelo.new
