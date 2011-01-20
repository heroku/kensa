require 'test/helper'

class AllCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @data = Manifest.new.skeleton
    @data['api']['password'] = 'secret'
    @data['api']['test'] += "working"
    @file = File.dirname(__FILE__) + "/resources/runner.rb"
  end

  def check; AllCheck; end

  test "valid on script exit 0" do
    @data[:args] = "ruby #{@file}"
    assert_valid
  end

  test "invalid on script exit non 0" do
    @data[:args] = "ruby #{@file} fail"
    assert_invalid
  end

end
