require 'test/helper'

class ManifestCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  def check ; ManifestCheck ; end

  test "doesn't barf on OkJson errors" do
    File.open("addon-manifest.json", 'w') { |f| f << "{,a" }
    assert_raises Client::CommandInvalid, "addon-manifest.json includes invalid JSON" do
      kensa "test provision"
    end
  end

  %w{get post}.each do |method|
    context "with sso #{method}" do
      setup { @data = Manifest.new(:method => method).skeleton }

      test "is valid if no errors" do
        assert_valid
      end

      test "has an id" do
        @data.delete("id")
        assert_invalid
      end

      test "api key exists" do
        @data.delete("api")
        assert_invalid
      end

      test "api is a Hash" do
        @data["api"] = ""
        assert_invalid
      end

      test "api has a list of regions" do
        @data["api"].delete("regions")
        assert_invalid
      end

      test "api has a list of regions including US" do
        @data["api"]["regions"] = ["eu"]
        assert_invalid
      end

      test "api only allows valid region names" do
        @data["api"]["regions"] = ["us", "ap"]
        assert_invalid
      end

      test "api has a password" do
        @data["api"].delete("password")
        assert_invalid
      end

      test "api contains test" do
        @data["api"].delete("test")
        assert_invalid
      end

      test "api contains production" do
        @data["api"].delete("production")
        assert_invalid
      end

      test "api contains production of https" do
        if method == 'get'
          @data["api"]["production"] = "http://foo.com"
        else
          @data["api"]["production"]['base_url'] = "http://foo.com"
        end
        assert_invalid
      end

      if method == 'post'
        test "sso contains production of https" do
          @data["api"]["production"]['sso_url'] = "http://foo.com"
          assert_invalid
        end
      end

      test "api does not require config_vars" do
        @data["api"].delete "config_vars"
        assert_valid
      end

      context "with config vars" do
        test "api contains config_vars array" do
          @data["api"]["config_vars"] = "test"
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
  end
end
