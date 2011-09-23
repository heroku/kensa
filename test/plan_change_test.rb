require 'test/helper'

class PlanTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @params = { :plan => "new_plan" }
  end

  def put(path, params = {}, auth_credentials = nil)
    if auth_credentials.nil?
      auth_credentials = [manifest["id"], manifest["api"]["password"]]
    end
    uri = URI.parse(base_url)
    uri.path = path
    if auth_credentials
      uri.userinfo = auth_credentials
    end
    response = RestClient.put("#{uri.to_s}", params)
    Response.new(response.code, response.body, response.cookies)
  rescue RestClient::Forbidden
    Response.new(403)
  rescue RestClient::Unauthorized
    Response.new(401)
  end

  test "working plan change call" do
    response = put "/heroku/resources/123", @params
    assert_equal 200, response.code, "FAILURE: Expected a 200 response code on successful plan change."
  end

  test "detects missing auth" do
    response = put "/heroku/resources/123", @params, auth = false
    assert_equal 401, response.code, "FAILED: Provisioning request should require authentication."

    response = put "/heroku/resources/123", @params, [manifest["id"]+"a", manifest["api"]["password"]]
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = put "/heroku/resources/123", @params, [manifest["id"], manifest["api"]["password"]+"a"]
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
