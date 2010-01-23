require File.dirname(__FILE__) + "/helper"
require "heroku/vendor"

class DeleteCheckTest < Test::Unit::TestCase
  include Heroku::Vendor

  setup do
    @data = Manifest.skeleton.merge :id => 123
  end

  def check ; DeleteCheck ; end

  test "valid on 200" do
    assert_valid do |check|
      stub :delete, check, [200, ""]
    end
  end

  test "status other than 200" do
    assert_invalid do |check|
      stub :delete, check, [500, ""]
    end
  end

end
