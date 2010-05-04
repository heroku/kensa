require 'rubygems'
require 'sinatra'
require 'json'

enable :sessions

helpers do
  def heroku_only!
    unless auth_heroku?
      response['WWW-Authenticate'] = %(Basic realm="Kensa Test Server")
      unauthorized!(401)
    end
  end

  def auth_heroku?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['test', 'secret']
  end

  def unauthorized!(status=403)
    throw(:halt, [status, "Not authorized\n"])
  end

  def make_token
    Digest::SHA1.hexdigest([params[:id], 'SSO_SALT', params[:timestamp]].join(':'))
  end
  
  def login
    session[:logged_in] = true
    redirect '/'
  end
end

post '/working/heroku/resources' do
  heroku_only!
  { :id => 123 }.to_json
end

post '/invalid-json/heroku/resources' do
  heroku_only!
  'invalidjson'
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


get '/working/heroku/resources/:id' do
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  unauthorized! unless params[:token] == make_token
  login
end

get '/notoken/heroku/resources/:id' do
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:timestamp].to_i > (Time.now-60*2).to_i
  login
end

get '/notimestamp/heroku/resources/:id' do
  unauthorized! unless params[:id] && params[:token]
  unauthorized! unless params[:token] == make_token
  login
end

get '/' do
  unauthorized! unless session[:logged_in]
  "OK"
end