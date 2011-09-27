require 'test/unit'
require 'artifice'
require 'rest-client'
require 'yajl'
require 'test/resources/provider_server'
require 'lib/heroku/kensa/manifest'
%w{response test_case formatter}.each do |lib|
  require "test/lib/#{lib}"
end
