require 'test/helper'

class InitTest < Test::Unit::TestCase
  include FsMock

  def test_init_doesnt_overwite_addon_manifest
    File.open(@filename, 'w') { |f| f << '{}' }
    any_instance_of(Heroku::Kensa::Client) do |client|
      stub(client).gets { 'n' }
      stub(client).print
      stub(client).puts
    end

    assert_raises SystemExit do
      kensa "init"
    end
  end
  
  def test_init_defaults_to_sso_post
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

  def assert_foreman_env(env, manifest)
    assert env.include?("SSO_SALT=#{manifest['api']['sso_salt']}\n")
    assert env.include?("HEROKU_USERNAME=#{manifest['id']}\n")
    assert env.include?("HEROKU_PASSWORD=#{manifest['api']['password']}")
  end

  def test_init_with_foreman_flag_and_get
    kensa "init --foreman --sso get"
    env = File.open(".env").read
    manifest = read_json(@filename)
    assert manifest['api']['test'] =~ /:5000/
    assert manifest['api']['test'] =~ /:5000/
    assert_foreman_env env, manifest
  end

  def test_init_with_foreman_flag_and_post
    kensa "init --foreman --sso post"
    env = File.open(".env").read
    manifest = read_json(@filename)
    assert manifest['api']['test']['base_url'] =~ /:5000/
    assert manifest['api']['test']['sso_url'] =~ /:5000/
    assert_foreman_env env, manifest
  end
end
