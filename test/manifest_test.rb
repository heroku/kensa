require 'contest'
require 'heroku/vendor'

class ManifestTest < Test::Unit::TestCase

  def assert_error(msg)
    errors = Array(@man.errors)
    assert_block "'#{msg}' is not contained in #{errors.inspect}" do
      errors.include?(msg)
    end
  end

  setup do
    @manifest = {
      "name" => "cloudcalc",

      "api" => {
        "host" => "localhost",
        "port" => "7774",
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
    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_nil @man.errors
  end

  test "invalid json gives error" do
    @man = Heroku::Vendor::Manifest.new("---")
    @man.check!

    assert_not_nil @man.errors
    assert_equal 1, @man.errors.size
    assert_match /^lexical error/, @man.errors.first
  end

  test "requires an api key" do
    @manifest.delete("api")

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`api` must exist"
  end

  test "requires api key to be a Hash" do
    @manifest["api"] = ""

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`api` must be a hash"
  end

  test "requires an plan key" do
    @manifest.delete("plans")

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` must exist"
  end

  test "requires plan to be a array" do
    @manifest["plans"] = ""

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` must be an array"
  end

  test "requires at least 1 plan" do
    @manifest["plans"] = []

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` must contain at least one plan"
  end

  test "each plan must have a name" do
    @manifest["plans"][0].delete("name")

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` at 0 - `name` must exist"
  end

  test "each plan must have a price" do
    @manifest["plans"].first.delete("price")

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` at 0 - `price` must exist"
  end

  test "each price must be an Integer" do
    @manifest["plans"].first["price"] = "fiddy cent"

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` at 0 - `price` must be an integer"
  end

  test "each plan must have a price unit" do
    @manifest["plans"].first.delete("price_unit")

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` at 0 - `price_unit` must exist"
  end

  test "each plans can only be month or dyno_hour" do
    @manifest["plans"].first["price_unit"] = "first ov da munth"

    @man = Heroku::Vendor::Manifest.new(@manifest)
    @man.check!

    assert_error "`plans` at 0 - `price_unit` must be [month|dyno_hour]"
  end

end
