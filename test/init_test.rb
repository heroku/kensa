require_relative 'helper'

class InitTest < MiniTest::Unit::TestCase
  include FsMock

  def test_doesnt_overwrite_an_existing_file
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

  def test_can_provilde_a_filename
    @filename = 'foo.json'

    kensa "init -f #{@filename}"
    assert !File.exist?('./addon-manifest.json')
    manifest = read_json(@filename)
  end

  def test_can_create_a_env_file_for_foreman
    kensa "init --foreman"
    env = File.open(".env").read
    manifest = read_json(@filename)

    assert env.include?("SSO_SALT=#{manifest['api']['sso_salt']}\n")
    assert env.include?("HEROKU_USERNAME=#{manifest['id']}\n")
    assert env.include?("HEROKU_PASSWORD=#{manifest['api']['password']}")
  end
end
