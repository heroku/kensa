require 'test/helper'

class DeprovisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @params = {}
  end

  def delete(path, auth_credentials = nil)
    if auth_credentials.nil?
      auth_credentials = [manifest["id"], manifest["api"]["password"]]
    end
    uri = URI.parse(base_url)
    uri.path = path
    if auth_credentials
      uri.userinfo = auth_credentials
    end
    response = RestClient.delete("#{uri.to_s}")
    Response.new(response.code, response.body, response.cookies)
  rescue RestClient::Forbidden
    Response.new(403)
  rescue RestClient::Unauthorized
    Response.new(401)
  end

  test "working deprovision call" do
    response = delete "/heroku/resources/123"
    assert_equal 200, response.code, "FAILURE: Expects a 200 - OK response/status code when successfully deprovisioned."
  end

  test "detects missing auth" do
    response = delete("/heroku/resources/123", auth = false)
    assert_equal 401, response.code, "FAILED: Provisioning request should require authentication."

    # response = post "/heroku/resources/123", [manifest["id"]+"a", manifest["api"]["password"]]
    # assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = post "/heroku/resources/123", [manifest["id"], manifest["api"]["password"]+"a"]
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
