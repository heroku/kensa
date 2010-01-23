require File.dirname(__FILE__) + '/helper'
require 'heroku/vendor'

class CheckTest < Test::Unit::TestCase

  setup do
    @manifest = {
      "name" => "cloudcalc",

      "api" => {
        "test" => "http://localhost:4567/",
        "production" => "https://cloudcalc.com/"
      },

      "plans" => [
        {
          "name" => "Basic",
          "price" => "0",
          "price_unit" => "month"
        }
      ]
    }
  end

  test "has no errors if everything is valid" do
    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_nil @data.errors
  end

  test "invalid json gives error" do
    @data = Heroku::Vendor::Manifest.new("---")
    @data.check!

    assert_not_nil @data.errors
    assert_equal 1, @data.errors.size
    assert_match /^lexical error/, @data.errors.first
  end

  test "requires an api key" do
    @manifest.delete("api")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`api` must exist"
  end

  test "requires api key to be a Hash" do
    @manifest["api"] = ""

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`api` must be a hash"
  end

  test "requires api have a test url" do
    @manifest["api"].delete("test")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`api` must have a url for `test`"
  end

  test "requires api have a production url" do
    @manifest["api"].delete("production")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`api` must have a url for `production`"
  end

  test "requires the production url to be https" do
    @manifest["api"]["production"] = "http://foo.com"

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`api` must have a url for `production` that is https"
  end

  test "requires an plan key" do
    @manifest.delete("plans")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` must exist"
  end

  test "requires plan to be a array" do
    @manifest["plans"] = ""

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` must be an array"
  end

  test "requires at least 1 plan" do
    @manifest["plans"] = []

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` must contain at least one plan"
  end

  test "each plan must have a name" do
    @manifest["plans"][0].delete("name")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` at 0 - `name` must exist"
  end

  test "each plan must have a price" do
    @manifest["plans"].first.delete("price")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` at 0 - `price` must exist"
  end

  test "each price must be an Integer" do
    @manifest["plans"].first["price"] = "fiddy cent"

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` at 0 - `price` must be an integer"
  end

  test "each plan must have a price unit" do
    @manifest["plans"].first.delete("price_unit")

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` at 0 - `price_unit` must exist"
  end

  test "each plans can only be month or dyno_hour" do
    @manifest["plans"].first["price_unit"] = "first ov da munth"

    @data = Heroku::Vendor::Manifest.new(@manifest)
    @data.check!

    assert_error "`plans` at 0 - `price_unit` must be [month|dyno_hour]"
  end

end
