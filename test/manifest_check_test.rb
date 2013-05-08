require_relative 'helper'

class ManifestCheckTest < MiniTest::Unit::TestCase
  include Heroku::Kensa

  def check ; ManifestCheck ; end

  def setup
    @data = Manifest.new(:method => "post").skeleton
  end

  def test_doesnt_barf_on_okjson_errors
    File.open("addon-manifest.json", 'w') { |f| f << "{,a" }
    assert_raises Client::CommandInvalid, "addon-manifest.json includes invalid JSON" do
      kensa "test provision"
    end
  end

  def test_is_valid_if_no_errors
    assert_valid
  end

  def test_has_an_id
    refute_nil @data["id"]
  end

  def test_id_is_a_string
    assert_kind_of String, @data["id"]
  end

  def test_id_is_not_blank
    refute_empty @data["id"]
  end

  def test_api_key_exists
    refute_empty @data["api"]
  end

  def test_api_is_a_hash
    assert_kind_of Hash, @data["api"]
  end

  def test_api_has_a_password
    refute_nil @data["api"]["password"]
    refute_empty @data["api"]["password"]
  end

  def test_api_contains_test
    refute_nil @data["api"]["test"]
    refute_empty @data["api"]["test"]
    assert_kind_of Hash, @data["api"]["test"]
  end

  def test_api_contains_production
    refute_nil @data["api"]["production"]
    refute_empty @data["api"]["production"]
    assert_kind_of Hash, @data["api"]["production"]
  end

  def test_api_contains_production_of_https
    assert_match %r{\Ahttps://}, @data["api"]["production"]["base_url"]
  end

  def test_sso_contains_production_of_https
    assert_match %r{\Ahttps://}, @data["api"]["production"]["sso_url"]
  end

  def test_api_does_not_require_config_vars
    pending "Need to re-implement"
    @data["api"].delete "config_vars"
    assert_valid
  end

  def test_api_contains_config_vars_array
    pending "Need to re-implement"
    @data["api"]["config_vars"] = "test"
    assert_invalid
  end

  def test_contains_at_least_one_config_var
    pending "Need to re-implement"
    @data["api"]["config_vars"].clear
    assert_invalid
  end

  def test_all_config_vars_are_in_upper_case
    pending "Need to re-implement"
    @data["api"]["config_vars"] << 'MYADDON_invalid_var'
    assert_invalid
  end

  def test_assert_config_var_prefixes_match_addon_id
    pending "Need to re-implement"
    @data["api"]["config_vars"] << 'MONGO_URL'
    assert_invalid
  end

  def test_replaces_dashes_for_underscores_on_the_config_var_check
    pending "Need to re-implement"
    @data["id"] = "MY-ADDON"
    @data["api"]["config_vars"] = ["MY_ADDON_URL"]
    assert_valid
  end

  def test_username_is_deprecated
    pending "Need to re-implement"
    @data["api"]["username"] = "heroku"
    assert_invalid
  end
end
