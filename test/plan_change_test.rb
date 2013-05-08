require_relative 'helper'
class PlanChangeTest < MiniTest::Unit::TestCase
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

  def test_requires_quthentication
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

  def test_returns_200_or_201_response
    response = authed_resource.put(valid_planchange_hash.to_json)
    assert (response.code == (200 || 201))
  end

  def test_returns_json
    response = authed_resource.put(valid_planchange_hash.to_json)
    hash = OkJson.decode(response.body)
    assert hash
  end
end
