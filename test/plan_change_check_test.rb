require 'test/helper'

class PlanChangeCheckTest < Test::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock

  context "with sso post" do
    setup do
      @data = Manifest.new(:method => "post").skeleton.merge :id => 123, :plan => 'premium'
      @data['api']['password'] = 'secret'
    end

    def check ; PlanChangeCheck ; end

    test "working plan change call" do
      use_provider_endpoint "working"
      assert_valid
    end

    test "detects invalid status" do
      use_provider_endpoint "invalid-status"
      assert_invalid
    end

    test "detects missing auth" do
      use_provider_endpoint "invalid-missing-auth"
      assert_invalid
    end
  end
end
