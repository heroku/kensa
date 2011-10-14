$:.unshift(File.expand_path("../..",__FILE__))
require 'test/helper'
require 'cgi'

module SsoSetupActions
  include Heroku::Kensa

  def sso_setup
    Timecop.freeze Time.utc(2010, 1)
    @data = Manifest.new.skeleton.merge(:id => 1)
    @data['api']['test'] = 'http://localhost:4567/'
    @data['api']['sso_salt'] = 'SSO_SALT'
    @sso = Sso.new @data
  end

  def asserts_builds_full_url(env)
    url, query = @sso.full_url.split('?')
    data = CGI.parse(query)

    assert_equal "#{@data['api'][env]}heroku/resources/1", url
    assert_equal 'b6010f6fbb850887a396c2bc0ab23974003008f6', data['token'].first
    assert_equal '1262304000', data['timestamp'].first
    assert_equal 'username@example.com', data['user'].first
  end
end

class SsoLaunchTest < Test::Unit::TestCase
  include SsoSetupActions

  def setup
    super
    sso_setup
  end

  def test_builds_path
    assert_equal '/heroku/resources/1', @sso.path
  end

  def test_builds_full_url
    asserts_builds_full_url('test')
  end
end

class SsoGetLaunchTest < Test::Unit::TestCase
  include SsoSetupActions

  def setup
    super
    sso_setup
    @data["api"]["test"] = "http://example.org/"
    @sso = Sso.new(@data).start
  end

  def test_sso_url_should_be_the_full_url
    assert_equal @sso.full_url, @sso.sso_url
  end

  def test_message_is_opening_full_url
    assert_equal "Opening #{@sso.full_url}", @sso.message
  end
end

class SsoPostLaunchTest < Test::Unit::TestCase
  include SsoSetupActions

  def setup
    super
    sso_setup
    @data['api']['test'] = {
      "base_url" => "http://localhost:4567",
      "sso_url" => "http://localhost:4567/users/login/sso"
    }
  end

  def test_it_starts_the_proxy_server
    Artifice.deactivate
    @sso = Sso.new(@data).start
    body = RestClient.get(@sso.sso_url)

    assert body.include? 'b6010f6fbb850887a396c2bc0ab23974003008f6'
    assert body.include? '1262304000'
    assert body.include? @sso.url
    assert body.include? @sso.sample_nav_data
  end
end

class SsoPostProxyLaunchTest < Test::Unit::TestCase
  include SsoSetupActions

  def setup
    super
    sso_setup
    @data['api']['test'] = {
      "base_url" => "http://localhost:4567",
      "sso_url" => "http://localhost:4567/users/login/sso"
    }
    any_instance_of(Sso, :run_proxy => false)
    @sso = Sso.new(@data).start
  end

  def test_sso_url_should_point_to_the_proxy
    assert_equal "http://localhost:#{@sso.proxy_port}/", @sso.sso_url
  end

  def test_post_url_contains_url_and_path
    assert_equal "http://localhost:4567/users/login/sso", @sso.post_url
  end

  def test_message_is_posting_data_to_post_url_via_proxy_on_port_proxy_port
    assert_equal "POSTing #{@sso.query_data} to #{@sso.post_url} via proxy on port #{@sso.proxy_port}", @sso.message
  end
end

class SsoEnvironmentLaunchTest < Test::Unit::TestCase
  include SsoSetupActions

  def setup
    super
    sso_setup
    env = 'production'
    @data[:env] = env
    @data['api'][env] = 'http://localhost:7654/'

    @sso = Sso.new @data
  end

  def test_builds_full_url
    asserts_builds_full_url('production')
  end
end
