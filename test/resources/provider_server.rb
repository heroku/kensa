require 'rubygems'
require 'sinatra'
require 'json'

class ProviderServer < Sinatra::Base
  set :views, File.dirname(__FILE__) + "/views"

  def initialize(manifest = nil)
    @manifest = manifest
    super
  end

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

    def check_timestamp!
      unauthorized! if params[:timestamp].to_i < (Time.now-60*2).to_i
    end

    def check_token!
      salt = @manifest && @manifest["sso_salt"]
      token = Digest::SHA1.hexdigest([params[:id], salt, params[:timestamp]].join(':'))
      unauthorized! if params[:token] != token
    end

  end

  get '/heroku/resources/:id' do
    check_timestamp!
    check_token!
    response.set_cookie('heroku-nav-data', params['nav-data'])
    session[:heroku] = true
    haml :index
  end

end
