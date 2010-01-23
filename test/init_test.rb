require 'contest'
require 'heroku/vendor'
require 'tempfile'

class InitTest < Test::Unit::TestCase

  test "creates a valid skeleton manifest" do
    file = Tempfile.new("heroku-addon-init-test")

    Heroku::Vendor::Manifest.init(file.path)

    man = Heroku::Vendor::Manifest.new(file.read)
    man.check!

    assert !man.errors?
  end

end
