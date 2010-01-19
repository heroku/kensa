require 'contest'
require 'heroku/vendor'

class ManifestTest < Test::Unit::TestCase

  test "invalid json gives error" do
    man = Heroku::Vendor::Manifest.new("---")
    man.check!

    assert_not_nil man.errors
    assert_equal 1, man.errors.size
    assert_match /^lexical error/, man.errors.first
  end

end
