require 'test/helper'

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @params = {}
  end

  def post(path, params = {}, auth_credentials = nil)
    if auth_credentials.nil?
      auth_credentials = [manifest["id"], manifest["api"]["password"]]
    end
    uri = URI.parse(base_url)
    uri.path = path
    if auth_credentials
      uri.userinfo = auth_credentials
    end
    response = RestClient.post("#{uri.to_s}", params)
    Response.new(response.code, response.body, response.cookies)
  rescue RestClient::Forbidden
    Response.new(403)
  rescue RestClient::Unauthorized
    Response.new(401)
  end

  test "working provision call" do
    response = post "/heroku/resources", @params
    assert_equal 201, response.code, "FAILURE: Expects a 201 - Created response/status code when successfully provisioned."
  end

  test "allows the definition of a custom provisioning endpoint" do
    #Artifice.activate_with(KensaServer.new)
    #@data['api']['test'] = {
    #  "base_url" => "https://example.org/providers/provision",
    #  "sso_url"  => "https://example.org/sso"
    #}
    #assert_valid
  end

  test "expects a valid JSON response" do
    response = post "/heroku/resources", @params
    assert response.json_body, "FAILURE: Expects a valid JSON object as response body."
  end

  test "detects missing id" do
    response = post "/heroku/resources", @params
    assert response.json_body["id"], "FAILURE: Expects JSON response to contain the Provider's unique ID for this app."
    assert response.json_body["id"].strip != "", "FAILURE: Expects JSON response to contain the Provider's unique ID for this app."
  end

  test "provides app config" do
    response = post "/heroku/resources", @params
    assert response.json_body["config"].is_a?(Hash), "FAILURE: Expects JSON response to contain a hash of config variables."
  end

  test "all config values are strings" do
    response = post "/heroku/resources", @params
    response.json_body["config"].each do |k,v|
      assert k.is_a?(String), "FAILURE: Expect all config names to be strings ('#{k}' is not)."
      assert v.is_a?(String), "FAILURE: Expect all config values to be strings ('#{v}' is not)."
    end
  end

  test "all config vars are defined in the manifest" do
    response = post "/heroku/resources", @params
    response.json_body["config"].each do |k,v|
      assert manifest["config_vars"].include?(k), "FAILURE: Only config vars defined in the manfiest can be set ('#{k}' is not)."
    end
  end

  test "all config URL values are valid" do
    response = post "/heroku/resources", @params
    response.json_body["config"].each do |k,v|
      next unless k =~ /_URL\z/
      begin
        uri = URI.parse(v)
        assert uri.host, "#{v} is not a valid URI - missing host"
        assert uri.scheme, "#{v} is not a valid URI - missing scheme"
      rescue URI::InvalidURIError
        assert false, "#{v} is not a valud URI"
      end
    end
  end

  test "detects missing auth" do
    response = post "/heroku/resources", @params, auth = false
    assert_equal 401, response.code, "FAILED: Provisioning request should require authentication."

    response = post "/heroku/resources", @params, [manifest["id"]+"a", manifest["api"]["password"]]
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = post "/heroku/resources", @params, [manifest["id"], manifest["api"]["password"]+"a"]
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
