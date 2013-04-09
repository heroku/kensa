require_relative 'helper'
class PlanChangeTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    @manifest = Manifest.new(:method => "post").skeleton
    @manifest['api']['password'] = 'secret'
    base_url = @manifest['api']['test']['base_url'].chomp("/")
    base_url += "/heroku/resources" unless base_url =~ %r{/heroku/resources\z}
    base_url += "/123"
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

  def authed_resource
    resource(@manifest['id'], @manifest['api']['password'])
  end

  def valid_planchange_hash
    {"heroku_id" => "app123@heroku.com",
     "plan" => "test",
     "callback_url" => "https://api.heroku.com/vendor/apps/app123%40heroku.com" }
  end

  test "requires quthentication" do
    assert_raises RestClient::Unauthorized do
      resource.put({})
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', 'incorrect-pass').put({})
    end

    assert_raises RestClient::Unauthorized do
      resource(@manifest['id'], 'incorrect-pass').put({})
    end

    assert_raises RestClient::Unauthorized do
      resource('incorrect-user', @manifest['api']['password']).put({})
    end

    assert_nothing_raised RestClient::Unauthorized do
      authed_resource.put(valid_planchange_hash.to_json)
    end
  end
end

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
