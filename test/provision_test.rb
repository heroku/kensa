$:.unshift(File.expand_path("../..",__FILE__))
require 'test/lib/dependencies'
class ProvisionTest < Test::Unit::TestCase

  def setup
    super
    @params = {}
  end

  def provision(auth = nil, params = @params)
    post "/heroku/resources", params, auth
  end

  def test_working_provision_call
    response = provision
    assert_equal 201, response.code, "Expects a 201 - Created response/status code when successfully provisioned."
  end

  def test_allows_the_definition_of_a_custom_provisioning_endpoint
    #Artifice.activate_with(KensaServer.new)
    #@data['api']['test'] = {
    #  "base_url" => "https://example.org/providers/provision",
    #  "sso_url"  => "https://example.org/sso"
    #}
    #assert_valid
  end

  def test_expects_a_valid_json_response
    response = provision
    assert response.json_body, "Expects a valid JSON object as response body."
  end

  def test_detects_missing_id
    response = provision
    assert response.json_body["id"], "Expects JSON response to contain the Provider's unique ID for this app."
    assert response.json_body["id"].to_s.strip != "", "Expects JSON response to contain the Provider's unique ID for this app."
  end

  def test_provides_app_config
    response = provision
    assert response.json_body["config"].is_a?(Hash), "Expects JSON response to contain a hash of config variables."
  end

  def test_all_config_values_are_strings
    response = provision
    response.json_body["config"].each do |k,v|
      assert k.is_a?(String), "Expect all config names to be strings ('#{k}' is not)."
      assert v.is_a?(String), "Expect all config values to be strings ('#{v}' is not)."
    end
  end

  def test_all_config_vars_are_defined_in_the_manifest
    response = provision
    response.json_body["config"].each do |k,v|
      assert manifest["api"]["config_vars"].include?(k), "Only config vars defined in the manfiest can be set ('#{k}' is not)."
    end
  end

  def test_all_config_url_values_are_valid
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

  def test_detects_missing_auth
    response = provision(auth = false)
    assert_equal 401, response.code, "Provisioning request should require authentication."

    response = provision(auth = [manifest["id"]+"a", manifest["api"]["password"]])
    assert_equal 401, response.code, "Provisioning request appears to allow any username, should require '#{manifest["id"]}'."

    response = provision(auth = [manifest["id"], manifest["api"]["password"]+"a"])
    assert_equal 401, response.code, "Provisioning request appears to allow any password, should require '#{manifest["api"]["password"]}'."
  end

end
