require 'contest'

class Test::Unit::TestCase

  def ValidManifest
    {
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

  def assert_error(msg)
    errors = Array(@data.errors)
    assert_block "'#{msg}' is not contained in #{errors.inspect}" do
      errors.include?(msg)
    end
  end

end
