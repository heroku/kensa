require 'rubygems'
require 'sinatra/base'

class Hash
  def to_json
    OkJson.encode(self)
  end
end

class ProviderServer < Sinatra::Base
helpers do
  def action_only!
    unless auth_action?
      response['WWW-Authenticate'] = %(Basic realm="Kensa Test Server")
      unauthorized!(401)
    end
  end

  def auth_action?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['myaddon', 'secret']
  end

  def unauthorized!(status=403)
    throw(:halt, [status, "Not authorized\n"])
  end

  def make_token
    Digest::SHA1.hexdigest([params[:id], 'SSO_SALT', params[:timestamp]].join(':'))
  end

  def json_must_include(keys)
    params = OkJson.decode(request.body.read)
    keys.each do |param|
      raise "#{param} not included with request" unless params.keys.include? param
    end
  end

  def login(action_user=true)
  @header = action_user
  haml <<-HAML
%html
%body
  - if @header
    #aio-header
      %h1 Action.IO
  %h1 Sample Addon
HAML
  end
end

post '/aio/resources' do
  action_only!
  { :id => 123 }.to_json
end

post '/working/aio/resources' do
  json_must_include(%w{action_id plan callback_url logplex_token options})
  action_only!
  { :id => 123 }.to_json
end

post '/cmd-line-options/aio/resources' do
  action_only!
  options = OkJson.decode(request.body.read)['options']
  raise "Where are my options?" unless options['foo'] && options['bar']
  { :id => 123 }.to_json
end

post '/foo/aio/resources' do
  action_only!
  'foo'
end

post '/invalid-json/aio/resources' do
  action_only!
  'invalidjson'
end

post '/invalid-response/aio/resources' do
  action_only!
  'null'
end

post '/invalid-status/aio/resources' do
  action_only!
  status 422
  { :id => 123 }.to_json
end

post '/invalid-missing-id/aio/resources' do
  action_only!
  { :noid => 123 }.to_json
end

post '/invalid-missing-auth/aio/resources' do
  { :id => 123 }.to_json
end


put '/working/aio/resources/:id' do
  json_must_include(%w{action_id plan})
  action_only!
  {}.to_json
end

put '/invalid-missing-auth/aio/resources/:id' do
  { :id => 123 }.to_json
end

put '/invalid-status/aio/resources/:id' do
  action_only!
  status 422
  {}.to_json
end


delete '/working/aio/resources/:id' do
  action_only!
  "Ok"
end

def sso
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('aio-nav-data', params['nav-data'])
  login
end

get '/working/aio/resources/:id' do
  sso
end

post '/working/sso/login' do
  #puts params.inspect
  sso
end

def notoken
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  response.set_cookie('aio-nav-data', params['nav-data'])
  login
end

get '/notoken/aio/resources/:id' do
  notoken
end

post '/notoken/sso/login' do
  notoken
end

def notimestamp
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:token] == make_token
  response.set_cookie('aio-nav-data', params['nav-data'])
  login
end

get '/notimestamp/aio/resources/:id' do
  notimestamp
end

post '/notimestamp/sso/login' do
  notimestamp
end

def nolayout
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('aio-nav-data', params['nav-data'])
  login(false)
end

get '/nolayout/aio/resources/:id' do
  nolayout
end

post '/nolayout/sso/login' do
  nolayout
end

def nocookie
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  login
end

get '/nocookie/aio/resources/:id' do
  nocookie
end

post '/nocookie/sso/login' do
  nocookie
end

def badcookie
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('aio-nav-data', 'wrong value')
  login
end

get '/badcookie/aio/resources/:id' do
  badcookie
end

post '/badcookie/sso/login' do
  badcookie
end

def sso_user
  head 404 unless params[:email] == 'username@example.com'
  sso
end

get '/user/aio/resources/:id' do
  sso_user
end

post '/user/sso/login' do
  sso_user
end

get '/' do
  unauthorized! unless session[:logged_in]
end

if $0 == __FILE__
 self.run!
end
end
