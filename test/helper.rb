require "rubygems"
require "bundler/setup"

require "#{File.dirname(__FILE__)}/../lib/heroku/kensa"
require 'test/libs'
require 'timecop'
require 'rr'

Response = Struct.new(:code, :body, :cookies) do
  def json_body
    Yajl::Parser.parse(self.body)
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def setup
    Timecop.freeze Time.now.utc
    Artifice.activate_with(ProviderServer.new(manifest))
  end

  def teardown
    Timecop.return
    Artifice.deactivate
  end

  def make_token(id, salt, timestamp)
    Digest::SHA1.hexdigest([id, salt, timestamp].join(':'))
  end

  def provider_request(meth, path, params = {}, auth_credentials = nil)
    if auth_credentials.nil?
      auth_credentials = [manifest["id"], manifest["api"]["password"]]
    end
    uri = URI.parse(base_url)
    uri.path = path
    if auth_credentials
      uri.userinfo = auth_credentials
    end
    opts = meth == :get ? { :params => params } : params
    response = RestClient.send(meth, "#{uri.to_s}", opts)
    Response.new(response.code, response.body, response.cookies)
  rescue RestClient::Forbidden
    Response.new(403)
  rescue RestClient::Unauthorized
    Response.new(401)
  end

  def get(path, params = {})
    provider_request(:get, path, params, auth = false)
  end

  def delete(path, auth_credentials = nil)
    provider_request(:delete, path, params = nil, auth_credentials)
  end

  def post(path, params = {}, auth_credentials = nil)
    provider_request(:post, path, params, auth_credentials)
  end

  def put(path, params = {}, auth_credentials = nil)
    provider_request(:put, path, params, auth_credentials)
  end

  def manifest
    return @manifest if @manifest
    @manifest ||= $manifest || Heroku::Kensa::Manifest.new.skeleton
  end

  def base_url
    manifest["api"]["test"].chomp("/")
  end
end
