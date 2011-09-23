require 'test/lib/dependencies'
class ProvisionTest < Test::Unit::TestCase

  setup do
    @params = {}
  end

  def provision(auth = nil, params = @params)
    post "/heroku/resources", params, auth
  end

  test "working provision call" do
    response = provision
    assert_equal 201, response.code, "Expects a 201 - Created response/status code when successfully provisioned."
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
    response = provision
    assert response.json_body, "Expects a valid JSON object as response body."
  end

  test "detects missing id" do
    response = provision
    assert response.json_body["id"], "Expects JSON response to contain the Provider's unique ID for this app."
    assert response.json_body["id"].strip != "", "Expects JSON response to contain the Provider's unique ID for this app."
  end

  test "provides app config" do
    response = provision
    assert response.json_body["config"].is_a?(Hash), "Expects JSON response to contain a hash of config variables."
  end

  test "all config values are strings" do
    response = provision
    response.json_body["config"].each do |k,v|
      assert k.is_a?(String), "Expect all config names to be strings ('#{k}' is not)."
      assert v.is_a?(String), "Expect all config values to be strings ('#{v}' is not)."
    end
  end

  test "all config vars are defined in the manifest" do
    response = provision
    response.json_body["config"].each do |k,v|
      assert manifest["api"]["config_vars"].include?(k), "Only config vars defined in the manfiest can be set ('#{k}' is not)."
    end
  end

  test "all config URL values are valid" do
    response = provision
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
    response = provision(auth = false)
    assert_equal 401, response.code, "Provisioning request should require authentication."

    response = provision(auth = [manifest["id"]+"a", manifest["api"]["password"]])
    assert_equal 401, response.code, "Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = provision(auth = [manifest["id"], manifest["api"]["password"]+"a"])
    assert_equal 401, response.code, "Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
