require 'test/unit'
require 'artifice'
require 'rest-client'
require 'yajl'
require 'lib/heroku/kensa/manifest'
%w{response test_case formatter}.each do |lib|
  require "test/lib/#{lib}"
end
