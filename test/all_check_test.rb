require 'test/helper'

class AllCheckTest < Test::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock
  include FsMock

  setup do
    @data = Manifest.new(:method => :get).skeleton
    @data["api"]["requires"] << "many_per_app"
    @data['api']['password'] = 'secret'
    @data['api']['test'] += "working"
    @file = File.dirname(__FILE__) + "/resources/runner.rb"
  end

  def check; AllCheck; end

  test "valid on script exit 0" do
    @data[:args] = ["ruby #{@file}"]
    assert_valid
  end

  test "invalid on script exit non 0" do
    @data[:args] = ["ruby #{@file} fail"]
    assert_invalid
  end

  test "all runs" do
    assert_nothing_raised do
      kensa "init"
      kensa "test all"
    end
  end
end
