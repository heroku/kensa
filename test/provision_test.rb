require_relative 'helper'

class ProvisionTest < MiniTest::Unit::TestCase
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

  def authed_resource
    resource(@manifest['id'], @manifest['api']['password'])
  end

  def valid_provision_hash
    {"heroku_id" => "app123@heroku.com",
     "plan" => "test",
     "callback_url" => "https://api.heroku.com/vendor/apps/app123%40heroku.com" }
  end

  def test_requires_authentication
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
      authed_resource.post(valid_provision_hash.to_json)
    end
  end

  def test_detects_missing_heroku_id
    assert_raises RestClient::UnprocessableEntity do
      params = valid_provision_hash.dup
      params.delete("heroku_id")
      authed_resource.post(params.to_json)
    end
  end

  def test_detects_missing_plan
    assert_raises RestClient::UnprocessableEntity do
      params = valid_provision_hash.dup
      params.delete("plan")
      authed_resource.post(params.to_json)
    end
  end

  def test_detects_callback_url
    assert_raises RestClient::UnprocessableEntity do
      params = valid_provision_hash.dup
      params.delete("callback_url")
      authed_resource.post(params.to_json)
    end
  end

  def test_detects_invalid_json
    assert_raises RestClient::UnprocessableEntity do
      authed_resource.post(valid_provision_hash.to_json[0..-3])
    end
  end

  def test_returns_200_or_201_response
    response = authed_resource.post(valid_provision_hash.to_json)
    assert (response.code == (200 || 201))
  end

  def test_returns_json_response
    response = authed_resource.post(valid_provision_hash.to_json)
    hash = OkJson.decode(response.body)
    assert hash
  end

  def test_returns_provider_id
    response = authed_resource.post(valid_provision_hash.to_json)
    hash = OkJson.decode(response.body)
    assert hash.has_key?("id")
  end

  def test_returns_app_config
    pending "Need to re-implement"
  end

end
