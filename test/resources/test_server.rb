require 'rubygems'
require 'sinatra'

enable :sessions

helpers do
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