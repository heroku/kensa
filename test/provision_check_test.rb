require File.dirname(__FILE__) + "/helper"
require "heroku/samorau"

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Samorau

  setup do
    @data = Manifest.skeleton
    @responses = [
      [200, to_json({ :id => 456 })],
      [401, "Unauthorized"]
    ]
  end

  def check ; ProvisionCheck ; end

  test "valid on 200 for the regular check, and 401 for the auth check" do
    assert_valid do |check|
      stub :post, check, @responses
    end
  end

  test "invalid JSON" do
    @responses[0] = [200, "---"]
    assert_invalid do |check|
      stub :post, check, @responses
    end
  end

  test "status other than 200" do
    @responses[0] = [500, to_json({ :id => 456 })]
    assert_invalid do |check|
      stub :post, check, @responses
    end
  end

  test "runs provision response check" do
    @responses[0] = [200, to_json({ :noid => 456 })]
    assert_invalid do |check|
      stub :post, check, @responses
    end
  end

  test "runs auth check" do
    @responses[1] = [200, to_json({ :id => 456 })]
    assert_invalid do |check|
      stub :post, check, @responses
    end
  end

end
