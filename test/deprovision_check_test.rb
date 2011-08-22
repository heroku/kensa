require 'test/helper'

class DeprovisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @data = Manifest.new.skeleton.merge :id => 123
    @responses = [
      [200, ""],
      [401, ""],
    ]
  end

  def check ; DeprovisionCheck ; end

  test "valid on 200" do
    assert_valid do |check|
      kensa_stub :delete, check, @responses
    end
  end

  test "status other than 200" do
    @responses[0] = [500, ""]
    assert_invalid do |check|
      kensa_stub :delete, check, @responses
    end
  end

  test "runs auth check" do
    @responses[1] = [200, ""]
    assert_invalid do |check|
      kensa_stub :delete, check, @responses
    end
  end

end
