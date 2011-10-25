module Heroku::Kensa::HTTPTest
  def make_token(id, salt, timestamp)
    Digest::SHA1.hexdigest([id, salt, timestamp].join(':'))
  end

  def provider_request(meth, path, params = {}, auth_credentials = nil)
    if auth_credentials.nil?
      auth_credentials = [manifest["id"], manifest["api"]["password"]]
    end
    if path =~ /http/
      uri = URI.parse(path)
    else
      uri = URI.parse(base_url)
      uri.path = path
    end
    if auth_credentials
      uri.userinfo = auth_credentials
    end
    opts = meth == :get ? { :params => params } : params
    response = RestClient.send(meth, "#{uri.to_s}", opts)
    Response.new(response.code, response.body, response.cookies)
  rescue Errno::ECONNREFUSED
    raise UserError.new("Unable to connect to your API.")
  rescue RestClient::Forbidden
    Response.new(403)
  rescue RestClient::Unauthorized
    Response.new(401)
  rescue RestClient::InternalServerError
    raise UserError.new("HTTP 500 Internal Server Error")
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
    if manifest["api"]["test"].is_a?(Hash)
      manifest["api"]["test"]["base_url"].chomp("/")
    else
      manifest["api"]["test"].chomp("/")
    end
  end
end
