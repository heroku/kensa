require File.dirname(__FILE__) + "/helper"
require 'contest'

class TestCreateTest < Test::Unit::TestCase

  describe "validation" do
    setup do
      @response = {
        "id" => 123,
        "config" => { "FOO" => "bar" }
      }
    end

    test "has no errors if everything is valid" do
      @data = Heroku::Vendor::CreateResponseCheck.new(@response)
      @data.check!

      assert_nil @data.errors
    end

    test "test response must have an id" do
      @response.delete("id")

      @data = Heroku::Vendor::CreateResponseCheck.new(@response)
      @data.check!

      assert_error "`id` must exist"
    end

    test "config must be a Hash if exists" do
      @response["config"] = ""

      @data = Heroku::Vendor::CreateResponseCheck.new(@response)
      @data.check!

      assert_error "`config` must be a hash"
    end

  end

end
