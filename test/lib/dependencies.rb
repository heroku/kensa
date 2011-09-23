base_path = File.dirname(__FILE__)
require 'contest'
require 'artifice'
require "#{base_path}/../resources/provider_server"
require "#{base_path}/../../lib/heroku/kensa/manifest"
%w{response test_case}.each do |lib|
  require "#{base_path}/#{lib}"
end
