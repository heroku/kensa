$:.unshift(File.expand_path("../..",__FILE__))
require 'test/lib/dependencies'

class CreateTest < Test::Unit::TestCase
  def kensa(cmd)
    `./bin/kensa #{cmd}`
  end

  def test_create_with_manifest
    kensa "create"
  end
end
