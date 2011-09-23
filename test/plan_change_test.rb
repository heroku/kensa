require 'test/helper'

class PlanTest < Test::Unit::TestCase

  setup do
    @params = { :plan => "new_plan" }
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
