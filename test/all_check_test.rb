require 'test/helper'

class AllCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @data = Manifest.new.skeleton
  end

  def check; AllCheck; end

  test "valid on script exit 0" do
    file = File.dirname(__FILE__) + "/helper/resources/all_test_valid.rb"
    @data[:args] = "ruby #{file}"
    assert_valid
  end

  test "invalid on script exit non 0" do
    file = File.dirname(__FILE__) + "/helper/resources/all_test_invalid.rb"
    @data[:args] = "ruby #{file}"
    assert_invalid
  end

end
