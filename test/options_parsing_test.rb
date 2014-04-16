require 'test/helper'

class OptionParsingTest < Test::Unit::TestCase 
  include Heroku::Kensa
  include FsMock

  def options_for_cmd(string)
    client = Client.new(string.split)
    options = client.options[:options]
  end

  test "parameters get forwarded to provider" do
    Artifice.activate_with(lambda { |env|
      params = OkJson.decode env['rack.input'].read
      options = params['options']
      assert_equal 'true', options['foo']
      assert_equal 'baz', options['bar']
      assert_equal 'baz', options['fap']
      [201, {}, 'hello']
    }) do 
      kensa "init --sso get"
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

  test "leaves normal args alone" do
    cmd = "test provision --foo --production --async --file foo.json --plan foo"
    assert_normal_options Client.new(cmd.split).options
  end

  test "works with single dash -s tyle flags" do
    cmd = "test provision --foo --production --async -f foo.json -p foo"
    assert_normal_options Client.new(cmd.split).options
  end

  test "parsing --flag" do
    options = options_for_cmd("test provision --foo")
    assert_equal 'true', options['foo']
  end

  test "parsing --flag=value (with equals)" do
    options = options_for_cmd("test provision --foo=bar")
    assert_equal 'bar', options['foo']
  end

  test "parsing --flag value (without equals)" do
    options = options_for_cmd("test provision --foo bar")
    assert_equal 'bar', options['foo']
  end

  test "parsing mixed" do
    options = options_for_cmd("test provision --foo --bar foo --baz")
    assert_equal 'true', options['foo']
    assert_equal 'true', options['baz']
    assert_equal 'foo',  options['bar']
  end
end
