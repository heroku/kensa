require 'rubygems'
require 'sinatra'
require 'json'
require "#{File.dirname(__FILE__)}/kensa_server"

class CustomServer < KensaServer
  set :views, File.dirname(__FILE__) + "/views"

  post '/providers/provision' do
    heroku_only!
    { :id => 123 }.to_json
  end
end
