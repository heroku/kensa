require 'test/helper'

class ProvisionResponseCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  def check ; ProvisionResponseCheck ; end

  setup do
    @response = { "id" => "123", 
                  "config" => {
                    "MYADDON_URL" => "http://example.com/resource",
                    "MYADDON_CONFIG" => "value" 
                }}
    @data = Manifest.new.skeleton.merge(:provision_response => @response)
    @data['api']['config_vars'] << "MYADDON_CONFIG"
  end

  test "is valid if no errors" do
    assert_valid
  end

  test "has an id" do
    @response.delete("id")
    assert_invalid
  end

  describe "when config is present" do

    test "is a hash" do
      @response["config"] = ""
      assert_invalid
    end

    test "each key is previously set in the manifest" do
      @response["config"]["MYSQL_URL"] = "http://..." 
      assert_invalid
    end

    test "each value is a string" do
      @response["config"]["MYADDON_URL"] = {} 
      assert_invalid
    end

    test "asserts _URL vars are valid URIs" do
      @response["config"]["MYADDON_URL"] = "abc:" 
      assert_invalid
    end

    test "asserts _URL vars have a host" do
      @response["config"]["MYADDON_URL"] = "path" 
      assert_invalid
    end

    test "asserts _URL vars have a scheme" do
      @response["config"]["MYADDON_URL"] = "//host/path" 
      assert_invalid
    end

    test "doesn't run URI test against other vars" do
      @response["config"]['MYADDON_CONFIG'] = "abc:"
      assert_valid
    end

    test "doesn't allow localhost URIs on production" do
      @data[:env] = 'production'
      @response["config"]["MYADDON_URL"] = "http://localhost/abc" 
      assert_invalid
    end

    test "is valid otherwise" do
      @response["config"]["MYADDON_URL"] = "http://localhost/abc" 
      assert_valid
    end

    describe "when syslog drain is required" do
      setup do
        @data["requires"] = ["syslog_drain"]
      end

      test "response is invalid without a syslog_drain_url" do
        @response['syslog_drain_url'] = ''
        assert_invalid
      end

      test "response is invalid if syslog_drain_url is invalid" do
        @response['syslog_drain_url'] = 'ftp://host.example.com'
        assert_invalid
      end

      test "response is valid with a syslog_drain_url" do
        @response['syslog_drain_url'] = 'syslog://log.example.com:9999'
        assert_valid
      end
    end
  end

end
