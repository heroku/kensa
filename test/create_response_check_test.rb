require File.dirname(__FILE__) + "/helper"
require 'heroku/samorau'

class CreateResponseCheckTest < Test::Unit::TestCase
  include Heroku::Samorau

  def check ; CreateResponseCheck ; end

  setup do
    @response = { "id" => "123" }
    @data = { :create_response => @response }
  end

  test "is valid if no errors" do
    assert_valid
  end

  test "has an id" do
    @response.delete("id")
    assert_invalid
  end

  describe "when config is present" do

    test "is a hash" do
      @data["config"] = ""
      assert_invalid
    end

    test "each key is a string" do
      @data["config"] = { {} => "bar" }
      assert_invalid
    end

    test "each value is a string" do
      @data["config"] = { "FOO" => {} }
      assert_invalid
    end

  end

end
