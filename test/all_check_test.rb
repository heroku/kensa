require 'test/helper'

class AllCheckTest < MiniTest::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock
  include FsMock

  def setup
    super
    @data = Manifest.new(:method => :get).skeleton
    @data['api']['password'] = 'secret'
    @data['api']['test'] += "working"
    @file = File.dirname(__FILE__) + "/resources/runner.rb"
  end

  def check; AllCheck; end

  def test_valid_on_script_exit_0
    pending "Need to re-implement"
    @data[:args] = ["ruby #{@file}"]
    assert_valid
  end

  def test_invalid_on_script_exit_non_0
    pending "Need to re-implement"
    @data[:args] = ["ruby #{@file} fail"]
    assert_invalid
  end

  def test_all_runs
    assert_nothing_raised do
      pending "Need to re-implement"
      kensa "init"
      kensa "test all"
    end
  end
end
