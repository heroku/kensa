require File.dirname(__FILE__) + "/helper"
require "heroku/sensei"

class SsoCheckTest < Test::Unit::TestCase
  include Heroku::Sensei

  setup do
    @data = Manifest.skeleton.merge :id => 123
    @responses = [
      [403, ""],
      [403, ""],
      [200, ""]
    ]
  end

  def check ; SsoCheck ; end

  test "rejects bad token" do
    @responses[0] = [200, ""]
    assert_invalid do |check|
      stub :get, check, @responses
    end
  end

  test "rejects bad timestamp do" do
    @responses[1] = [200, ""]
    assert_invalid do |check|
      stub :get, check, @responses
    end
  end

  test "accepts sso otherwise" do
    assert_valid do |check|
      stub :get, check, @responses
    end
  end

end
