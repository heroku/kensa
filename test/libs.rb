require 'contest'
require 'artifice'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |lib|
  next if lib =~ /kensa_server/
  require lib
end
require "#{File.dirname(__FILE__)}/../lib/heroku/kensa/manifest"
