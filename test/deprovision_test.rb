require 'test/lib/dependencies'
class DeprovisionTest < Test::Unit::TestCase

  setup do
    @params = {}
  end

  def deprovision(auth = nil)
    delete "/heroku/resources/123", auth
  end

  test "working deprovision call" do
    response = deprovision
    assert_equal 200, response.code, "FAILURE: Expects a 200 - OK response/status code when successfully deprovisioned."
  end

  test "detects missing auth" do
    response = deprovision(auth = false)
    assert_equal 401, response.code, "FAILED: Provisioning request should require authentication."

    response = deprovision(auth = [manifest["id"]+"a", manifest["api"]["password"]])
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = deprovision(auth = [manifest["id"], manifest["api"]["password"]+"a"])
    assert_equal 401, response.code, "FAILED: Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
