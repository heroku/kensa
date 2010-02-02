require File.dirname(__FILE__) + "/helper"
require "heroku/samorau"

class CreateCheckTest < Test::Unit::TestCase
  include Heroku::Samorau

  setup do
    @data = Manifest.skeleton
  end

  def check ; CreateCheck ; end

  test "valid on 200" do
    assert_valid do |check|
      stub :post, check, [200, to_json({ :id => 456 })]
    end
  end

  test "invalid JSON" do
    assert_invalid do |check|
      stub :post, check, [200, "---"]
    end
  end

  test "status other than 200" do
    assert_invalid do |check|
      stub :post, check, [500, to_json({ :id => 456 })]
    end
  end

  test "runs create response check" do
    assert_invalid do |check|
      stub :post, check, [200, to_json({ :noid => 456 })]
    end
  end

end
