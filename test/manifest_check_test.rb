require_relative 'helper'

class ManifestCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  def check ; ManifestCheck ; end

  setup do
    @data = Manifest.new(:method => "post").skeleton
  end

  test "doesn't barf on OkJson errors" do
    File.open("addon-manifest.json", 'w') { |f| f << "{,a" }
    assert_raises Client::CommandInvalid, "addon-manifest.json includes invalid JSON" do
      kensa "test provision"
    end
  end

  test "is valid if no errors" do
    assert_valid
  end

  test "has an id" do
    refute_nil @data["id"]
  end

  test "id is a string" do
    assert_kind_of String, @data["id"]
  end

  test "id is not blank" do
    refute_empty @data["id"]
  end

  test "api key exists" do
    refute_empty @data["api"]
  end

  test "api is a Hash" do
    assert_kind_of Hash, @data["api"]
  end

  test "api has a password" do
    refute_nil @data["api"]["password"]
    refute_empty @data["api"]["password"]
  end

  test "api contains test" do
    refute_nil @data["api"]["test"]
    refute_empty @data["api"]["test"]
    assert_kind_of Hash, @data["api"]["test"]
  end

  test "api contains production" do
    refute_nil @data["api"]["production"]
    refute_empty @data["api"]["production"]
    assert_kind_of Hash, @data["api"]["production"]
  end

  test "api contains production of https" do
    assert_match %r{\Ahttps://}, @data["api"]["production"]["base_url"]
  end

  test "sso contains production of https" do
    assert_match %r{\Ahttps://}, @data["api"]["production"]["sso_url"]
  end

  test "api does not require config_vars" do
    pending "Need to re-implement"
    @data["api"].delete "config_vars"
    assert_valid
  end

  context "with config vars" do
    test "api contains config_vars array" do
      @data["api"]["config_vars"] = "test"
      assert_invalid
    end

    test "contains at least one config var" do
      @data["api"]["config_vars"].clear
      assert_invalid
    end

    test "all config vars are in upper case" do
      @data["api"]["config_vars"] << 'MYADDON_invalid_var'
      assert_invalid
    end

    test "assert config var prefixes match addon id" do
      @data["api"]["config_vars"] << 'MONGO_URL'
      assert_invalid
    end

    test "replaces dashes for underscores on the config var check" do
      @data["id"] = "MY-ADDON"
      @data["api"]["config_vars"] = ["MY_ADDON_URL"]
      assert_valid
    end
  end

  test "username is deprecated" do
    @data["api"]["username"] = "heroku"
    assert_invalid
  end
end
