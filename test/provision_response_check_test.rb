require 'test/helper'

class ProvisionResponseCheckTest < MiniTest::Unit::TestCase
  include Heroku::Kensa

  def check ; ProvisionResponseCheck ; end

  def setup
    @response = { "id" => "123",
                  "config" => {
                    "MYADDON_URL" => "http://example.com/resource",
                    "MYADDON_CONFIG" => "value"
                }}
    @data = Manifest.new.skeleton.merge(:provision_response => @response)
    @data['api']['config_vars'] << "MYADDON_CONFIG"
  end

  def test_is_valid_if_no_errors
    pending "Need to re-implement"
    assert_valid
  end

  def test_has_an_id
    pending "Need to re-implement"
    @response.delete("id")
    assert_invalid
  end

  describe "when config is present" do

    def test_is_a_hash
      pending "Need to re-implement"
      @response["config"] = ""
      assert_invalid
    end

    def test_each_key_is_previously_set_in_the_manifest
      pending "Need to re-implement"
      @response["config"]["MYSQL_URL"] = "http://..."
      assert_invalid
    end

    def test_each_value_is_a_string
      pending "Need to re-implement"
      @response["config"]["MYADDON_URL"] = {}
      assert_invalid
    end

    def test_asserts__url_vars_are_valid_uris
      pending "Need to re-implement"
      @response["config"]["MYADDON_URL"] = "abc:"
      assert_invalid
    end

    def test_asserts__url_vars_have_a_host
      pending "Need to re-implement"
      @response["config"]["MYADDON_URL"] = "path"
      assert_invalid
    end

    def test_asserts__url_vars_have_a_scheme
      pending "Need to re-implement"
      @response["config"]["MYADDON_URL"] = "//host/path"
      assert_invalid
    end

    def test_doesnt_run_uri_test_against_other_vars
      pending "Need to re-implement"
      @response["config"]['MYADDON_CONFIG'] = "abc:"
      assert_valid
    end

    def test_doesnt_allow_localhost_uris_on_production
      pending "Need to re-implement"
      @data[:env] = 'production'
      @response["config"]["MYADDON_URL"] = "http://localhost/abc"
      assert_invalid
    end

    def test_asserts_all_vars_in_manifest_are_in_response
      pending "Need to re-implement"
      @response["config"].delete('MYADDON_CONFIG')
      assert_invalid
    end

    def test_is_valid_otherwise
      pending "Need to re-implement"
      @response["config"]["MYADDON_URL"] = "http://localhost/abc"
      assert_valid
    end
  end

end
