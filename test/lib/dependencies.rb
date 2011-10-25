require 'test/unit'
require 'artifice'
require 'rest-client'
require 'yajl'
require 'lib/heroku/kensa/manifest'
%w{response http formatter}.each do |lib|
  require "test/lib/#{lib}"
end

class Test::Unit::TestCase
  include Heroku::Kensa::HTTPTest
end
