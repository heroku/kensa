require 'rubygems'
require 'sinatra/base'

class Hash
  def to_json
    OkJson.encode(self)
  end
end

class ProviderServer < Sinatra::Base
helpers do
  def heroku_only!
    unless auth_heroku?
      response['WWW-Authenticate'] = %(Basic realm="Kensa Test Server")
      unauthorized!(401)
    end
  end

  def auth_heroku?
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
  
  def login(heroku_user=true)
  @header = heroku_user
  erb <<-ERB
<html>
  <body>
    <% if @header %>
      <div id="heroku-header">
        <h1>Heroku</h1>
      </div>
    <% end %>
    <h1>Sample Add-on</h1>
  </body>
</html>
ERB
  end
end

post '/heroku/resources' do
  heroku_only!
  { :id => 123 }.to_json
end

post '/working/heroku/resources' do
  json_must_include(%w{heroku_id plan callback_url logplex_token options})
  heroku_only!
  { :id => 123 }.to_json
end

post '/cmd-line-options/heroku/resources' do
  heroku_only!
  options = OkJson.decode(request.body.read)['options']
  raise "Where are my options?" unless options['foo'] && options['bar']
  { :id => 123 }.to_json
end

post '/foo/heroku/resources' do
  heroku_only!
  'foo'
end

post '/invalid-json/heroku/resources' do
  heroku_only!
  'invalidjson'
end

post '/invalid-response/heroku/resources' do
  heroku_only!
  'null'
end

post '/invalid-status/heroku/resources' do
  heroku_only!
  status 422
  { :id => 123 }.to_json
end

post '/invalid-missing-id/heroku/resources' do
  heroku_only!
  { :noid => 123 }.to_json
end

post '/invalid-missing-auth/heroku/resources' do
  { :id => 123 }.to_json
end


put '/working/heroku/resources/:id' do
  json_must_include(%w{heroku_id plan})
  heroku_only!
  {}.to_json
end

put '/invalid-missing-auth/heroku/resources/:id' do
  { :id => 123 }.to_json
end

put '/invalid-status/heroku/resources/:id' do
  heroku_only!
  status 422
  {}.to_json
end


delete '/working/heroku/resources/:id' do
  heroku_only!
  "Ok"
end

def sso
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('heroku-nav-data', params['nav-data'])
  login
end

get '/working/heroku/resources/:id' do
  sso
end

post '/working/sso/login' do
  #puts params.inspect
  sso
end

def notoken
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  response.set_cookie('heroku-nav-data', params['nav-data'])
  login
end

get '/notoken/heroku/resources/:id' do
  notoken
end

post '/notoken/sso/login' do
  notoken
end

def notimestamp
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:token] == make_token
  response.set_cookie('heroku-nav-data', params['nav-data'])
  login
end

get '/notimestamp/heroku/resources/:id' do
  notimestamp
end

post '/notimestamp/sso/login' do
  notimestamp
end

def nolayout
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('heroku-nav-data', params['nav-data'])
  login(false)
end

get '/nolayout/heroku/resources/:id' do
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

get '/nocookie/heroku/resources/:id' do
  nocookie
end

post '/nocookie/sso/login' do
  nocookie
end

def badcookie
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  response.set_cookie('heroku-nav-data', 'wrong value')
  login
end

get '/badcookie/heroku/resources/:id' do
  badcookie
end

post '/badcookie/sso/login' do
  badcookie
end

def sso_user
  head 404 unless params[:email] == 'username@example.com'
  sso
end

get '/user/heroku/resources/:id' do
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
