require_relative 'helper'

class OptionParsingTest < MiniTest::Unit::TestCase
  include Heroku::Kensa
  include FsMock

  def options_for_cmd(string)
    client = Client.new(string.split)
    options = client.options[:options]
  end

  def test_parameters_get_forwarded_to_provider
    Artifice.activate_with(lambda { |env|
      params = OkJson.decode env['rack.input'].read
      options = params['options']
      assert_equal 'true', options['foo']
      assert_equal 'baz', options['bar']
      assert_equal 'baz', options['fap']
      [201, {}, 'hello']
    }) do
      kensa "init"
      kensa "test provision --foo --bar=baz --fap baz"
    end
  end

  def assert_normal_options(options)
    assert_equal true,   options[:async]
    assert_equal 'true', options[:options]['foo']
    assert_equal 'foo',  options[:plan]
    assert_equal 'foo.json',   options[:filename]
    assert_equal 'production', options[:env]
  end

  def test_leaves_normal_args_alone
    cmd = "test provision --foo --production --async --file foo.json --plan foo"
    assert_normal_options Client.new(cmd.split).options
  end

  def test_works_with_single_dash_style_flags
    cmd = "test provision --foo --production --async -f foo.json -p foo"
    assert_normal_options Client.new(cmd.split).options
  end

  def test_parsing_flag
    options = options_for_cmd("test provision --foo")
    assert_equal 'true', options['foo']
  end

  def test_parsing_flag_equal_value
    options = options_for_cmd("test provision --foo=bar")
    assert_equal 'bar', options['foo']
  end

  def test_parsing_flag_value
    options = options_for_cmd("test provision --foo bar")
    assert_equal 'bar', options['foo']
  end

  def test_parsing_mixed
    options = options_for_cmd("test provision --foo --bar foo --baz")
    assert_equal 'true', options['foo']
    assert_equal 'true', options['baz']
    assert_equal 'foo',  options['bar']
  end
end
