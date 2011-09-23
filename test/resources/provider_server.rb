require 'sinatra'
require 'json'

class ProviderServer < Sinatra::Base
  set :views, File.dirname(__FILE__) + "/views"

  def initialize(manifest = nil)
    @manifest = manifest
    super
  end

  helpers do
    def unauthorized!(status=403)
      halt status, "Not authorized\n"
    end

    def check_timestamp!
      unauthorized! if params[:timestamp].to_i < (Time.now-60*2).to_i
    end

    def check_token!
      salt = @manifest && @manifest["sso_salt"]
      token = Digest::SHA1.hexdigest([params[:id], salt, params[:timestamp]].join(':'))
      unauthorized! if params[:token] != token
    end

    def authenticate!
      unless auth_heroku?
        response['WWW-Authenticate'] = %(Basic realm="Kensa Test Server")
        unauthorized!(401)
      end
    end

    def auth_heroku?
      auth =  Rack::Auth::Basic::Request.new(request.env)
      return false unless auth.provided? && auth.basic? && auth.credentials
      if @manifest
        auth.credentials == [@manifest["id"], @manifest["api"]["password"]]
      else
        auth.credentials == ['myaddon', 'secret']
      end
    end
  end

  delete '/heroku/resources/:id' do
    authenticate!
    status 200
  end

  put '/heroku/resources/:id' do
    authenticate!
    status 200
  end

  post '/heroku/resources' do
    authenticate!
    status 201
    { "id" => 52343.to_s,
      "config" => {
        "MYADDON_USER" => "1",
        "MYADDON_URL" => "http://host.example.org/"
      }
    }.to_json
  end

  get '/heroku/resources/:id' do
    check_timestamp!
    check_token!
    response.set_cookie('heroku-nav-data', params['nav-data'])
    session[:heroku] = true
    haml :index
  end

  post '/sso/login' do
    check_timestamp!
    check_token!
    response.set_cookie('heroku-nav-data', params['nav-data'])
    session[:heroku] = true
    haml :index
  end

end
