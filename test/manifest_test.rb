require 'test/helper'
class ManifestTest < Test::Unit::TestCase

  def test_has_an_id
    assert manifest["id"], "Manifest needs to specify the ID of the add-on."
  end

  def test_has_a_hash_of_api_settings
    assert manifest["api"], "Manifest needs to contain a Hash of API settings."
    assert manifest["api"].is_a?(Hash), "Manifest needs to contain a Hash of API settings."
  end

  def test_api_has_a_password
    assert manifest["api"]["password"], "Manifest must define a password within the API settings."
  end

  def test_api_contains_test
    assert manifest["api"]["test"], "Manifest must define a test environment with the API settings."
  end

  def test_api_contains_production
    assert manifest["api"]["production"], "Manifest must define a production environment with the API settings."
  end

  def test_api_contains_production_of_https
    if manifest["api"]["production"].is_a?(Hash)
      url = manifest["api"]["production"]["base_url"]
    else
      url = manifest["api"]["production"]
    end
    assert url.match(%r{\Ahttps://}), "Production environment must communicate over HTTPS."
  end

  def test_all_config_vars_are_in_upper_case
    manifest["api"]["config_vars"].each do |var|
      assert_equal var.upcase, var, "All config vars must be uppercase, #{var} is not."
    end
  end

  def test_assert_config_var_prefixes_match_addon_id
    id = manifest["id"].upcase.gsub("-", "_")
    manifest["api"]["config_vars"].each do |var|
      assert var.match(%r{\A#{id}_}), "All config vars must be prefixed with the add-on ID (#{id}), #{var} is not."
    end
  end

  def test_username_is_deprecated
    assert !manifest["api"]["username"], "Username has been deprecated."
  end
end
