require 'test/lib/dependencies'
class PlanChangeTest < Test::Unit::TestCase

  setup do
    @params = { :plan => "new_plan" }
  end

  def plan_change(auth = nil, params = @params)
    response = put "/heroku/resources/123", params, auth
  end

  test "working plan change call" do
    response = plan_change
    assert_equal 200, response.code, "Expected a 200 response code on successful plan change."
  end

  test "detects missing auth" do
    response = plan_change(auth = false)
    assert_equal 401, response.code, "Provisioning request should require authentication."

    response = plan_change(auth = [manifest["id"]+"a", manifest["api"]["password"]])
    assert_equal 401, response.code, "Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = plan_change(auth = [manifest["id"], manifest["api"]["password"]+"a"])
    assert_equal 401, response.code, "Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
