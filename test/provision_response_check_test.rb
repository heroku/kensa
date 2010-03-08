require File.dirname(__FILE__) + "/helper"
require 'heroku/samorau'

class ProvisionResponseCheckTest < Test::Unit::TestCase
  include Heroku::Samorau

  def check ; ProvisionResponseCheck ; end

  setup do
    @response = { "id" => "123" }
    @data = Manifest.skeleton.merge(:provision_response => @response)
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
      @response["config"] = { "MYSQL_URL" => "http://..." }
      assert_invalid
    end

    test "each value is a string" do
      @response["config"] = { "MYADDON_URL" => {} }
      assert_invalid
    end

    test "is valid otherwise" do
      @response["config"] = { "MYADDON_URL" => "http://..." }
      assert_valid
    end
  end

end
