require 'contest'
require 'artifice'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |lib|
  require lib
end
require "#{File.dirname(__FILE__)}/../lib/heroku/kensa/manifest"
