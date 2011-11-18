require 'test/helper'
require 'fakefs/safe'

class InitTest < Test::Unit::TestCase
  def setup
    FakeFS.activate!
    @filename = 'addon-manifest.json'
  end

  def teardown
    File.unlink(@filename) if @filename && File.exist?(@filename)
    FakeFS.deactivate!
  end
  
  def test_init_default_so_sso_post
    kensa "init"
    manifest = read_json(@filename)
    %w{test production}.each do |env|
      %w{base_url sso_url}.each do |url|
        assert manifest['api'][env][url] =~ /^http/
      end
    end
    assert !File.exist?('.env')
  end

  def test_init_uses_file_flag
    @filename = 'foo.json'

    kensa "init -f #{@filename}"
    assert !File.exist?('./addon-manifest.json')
    assert !File.exist?('.env')
    manifest = read_json(@filename)
  end

  def test_init_uses_sso_flag
    kensa "init --sso get"
    manifest = read_json(@filename)
    %w{test production}.each do |env|
      assert manifest['api'][env] =~ /^http/
    end
    assert !File.exist?('.env')
  end

  def test_init_with_env_flag
    kensa "init --foreman"
    env = File.open(".env").read
    manifest = read_json(@filename)
    assert env.include?("SSO_SALT=#{manifest['api']['sso_salt']}\n")
    assert env.include?("HEROKU_USERNAME=#{manifest['id']}\n")
    assert env.include?("HEROKU_PASSWORD=#{manifest['api']['password']}")
  end
end
