require 'rubygems'
require 'thor'
require 'thor/group'

class Tests < Thor
  
  desc 'all', "Perform tests using test/contest"
  def all
    Dir.glob(File.join('tests', '*.rb')).sort.each { |f| puts(`ruby #{f}`) unless f =~ /env.rb/ }
  end

end
