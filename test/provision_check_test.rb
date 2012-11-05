require 'test/helper'

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock

  def check ; ProvisionCheck ; end

  ['get', 'post'].each do |method| 
    context "with sso #{method}" do
      setup do
        @data = Manifest.new(:method => method).skeleton
        @data['api']['password'] = 'secret'
      end

      test "trims url" do
        c = check.new(@data)
        assert_equal c.url, 'http://localhost:4567' 
      end

      test "supports subdomains with the same name as path" do
        @data['api']['test'] = {'base_url' => 'http://heroku.myhost.dev/heroku'}
        c = check.new(@data)
        assert_equal c.url, 'http://heroku.myhost.dev' 
      end

      test "working provision call" do
        use_provider_endpoint "working"
        assert_valid
      end

      test "provision call with extra params" do
        use_provider_endpoint "cmd-line-options"
        @data[:options] = {:foo => 'bar', :bar => 'baz'}
        assert_valid
      end

      # OkJson doesn't handle short strings correctly
      test "doesn't choke on foo" do
        use_provider_endpoint "foo"
        assert_invalid
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
