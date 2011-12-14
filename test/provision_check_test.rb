require 'test/helper'

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock

  def check ; ProvisionCheck ; end

  test "parameter parsing" do
    Artifice.activate_with(lambda { |env|
      params = OkJson.decode env['rack.input'].read
      options = params['options']
      assert_equal 'true', options['foo']
      assert_equal 'baz', options['bar']
      [201, {}, 'hello']
    }) do 
      kensa "init --sso get"
      kensa "test provision --foo --bar=baz"
    end
  end

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

      test "working provision call" do
        use_provider_endpoint "working"
        assert_valid
      end

      test "provision call with extra params" do
        use_provider_endpoint "cmd-line-options"
        @data[:options] = {:foo => 'bar', :bar => 'baz'}
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
