require 'test/helper'

class ManifestTest < Test::Unit::TestCase

  test "has an id" do
    assert manifest["id"], "FAILURE: Manifest needs to specify the ID of the add-on."
  end

  test "has a Hash of API settings" do
    assert manifest["api"], "FAILURE: Manifest needs to contain a Hash of API settings."
    assert manifest["api"].is_a?(Hash), "FAILURE: Manifest needs to contain a Hash of API settings."
  end

  test "api has a password" do
    assert manifest["api"]["password"], "FAILURE: Manifest must define a password within the API settings."
  end

  test "api contains test" do
    assert manifest["api"]["test"], "FAILURE: Manifest must define a test environment with the API settings."
  end

  test "api contains production" do
    assert manifest["api"]["production"], "FAILURE: Manifest must define a production environment with the API settings."
  end

  test "api contains production of https" do
    assert manifest["api"]["production"].match(%r{\Ahttps://}), "FAILURE: Production environment must communicate over HTTPS."
  end

  test "all config vars are in upper case" do
    manifest["api"]["config_vars"].each do |var|
      assert_equal var.upcase, var, "FAILURE: All config vars must be uppercase, #{var} is not."
    end
  end

  test "assert config var prefixes match addon id" do
    id = manifest["id"].upcase.gsub("-", "_")
    manifest["api"]["config_vars"].each do |var|
      assert var.match(%r{\A#{id}_}), "FAILURE: All config vars must be prefixed with the add-on ID (#{id}), #{var} is not."
    end
  end

  test "username is deprecated" do
    assert !manifest["api"]["username"], "FAILURE: Username has been deprecated."
  end
end
