require_relative 'helper'

class ProvisionTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    @manifest = Manifest.new(:method => "post").skeleton
    @manifest['api']['password'] = 'secret'
    base_url = @manifest['api']['test']['base_url'].chomp("/")
    base_url += "/heroku/resources" unless base_url =~ %r{/heroku/resources\z}
    @uri = URI.parse(base_url)
    Artifice.activate_with(ProviderServer)
    super
  end

  def teardown
    super
    Artifice.deactivate
  end


  def resource(user = nil, pass = nil)
    RestClient::Resource.new(@uri.to_s, user, pass)
  end

  test "requires quthentication" do
    assert_raises RestClient::Unauthorized do
      resource.post({})
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', 'incorrect-pass').post({})
    end

    assert_raises RestClient::Unauthorized do
      resource(@manifest['id'], 'incorrect-pass').post({})
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', @manifest['api']['password']).post({})
    end

    assert_nothing_raised RestClient::Unauthorized do
      resource(@manifest['id'], @manifest['api']['password']).post({})
    end
  end

  test "detects missing Heroku ID" do
  end

  test "returns JSON response" do
  end

  test "returns Provider ID" do
  end

end

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
    end
  end
end
