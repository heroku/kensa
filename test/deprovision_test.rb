$:.unshift(File.expand_path("../..",__FILE__))
require 'test/lib/dependencies'
class DeprovisionTest < Test::Unit::TestCase

  def setup
    super
    @params = {}
  end

  def deprovision(auth = nil)
    delete "/heroku/resources/123", auth
  end

  def test_working_deprovision_call
    response = deprovision
    assert_equal 200, response.code, "Expects a 200 - OK response/status code when successfully deprovisioned."
  end

  def test_detects_missing_auth
    response = deprovision(auth = false)
    assert_equal 401, response.code, "Provisioning request should require authentication."

    response = deprovision(auth = [manifest["id"]+"a", manifest["api"]["password"]])
    assert_equal 401, response.code, "Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = deprovision(auth = [manifest["id"], manifest["api"]["password"]+"a"])
    assert_equal 401, response.code, "Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
