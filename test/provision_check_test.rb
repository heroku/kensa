require 'test/helper'

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  ['get', 'post'].each do |method| 
    context "with sso #{method}" do
      setup do
        @data = Manifest.new(:method => method).skeleton
        @data['api']['password'] = 'secret'
      end

      def check ; ProvisionCheck ; end

      test "working provision call" do
        use_provider_endpoint "working"
        assert_valid
      end

      test "detects invalid JSON" do
        use_provider_endpoint "invalid-json"
        assert_invalid
      end

      test "detects invalid response" do
        use_provider_endpoint "invalid-response"
        assert_invalid
      end

      test "detects invalid status" do
        use_provider_endpoint "invalid-status"
        assert_invalid
      end

      test "detects missing id" do
        use_provider_endpoint "invalid-missing-id"
        assert_invalid
      end

      test "detects missing auth" do
        use_provider_endpoint "invalid-missing-auth"
        assert_invalid
      end
    end
  end
end
