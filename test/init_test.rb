require_relative 'helper'

class InitTest < Test::Unit::TestCase
  include FsMock

  context "initializing a manifest" do
    test "doesn-t overwrite an existing file" do
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

    test "can provilde a filename" do
      @filename = 'foo.json'

      kensa "init -f #{@filename}"
      assert !File.exist?('./addon-manifest.json')
      manifest = read_json(@filename)
    end

    test "can create a .env file for foreman" do
      kensa "init --foreman"
      env = File.open(".env").read
      manifest = read_json(@filename)

      assert env.include?("SSO_SALT=#{manifest['api']['sso_salt']}\n")
      assert env.include?("HEROKU_USERNAME=#{manifest['id']}\n")
      assert env.include?("HEROKU_PASSWORD=#{manifest['api']['password']}")
    end
  end
end
