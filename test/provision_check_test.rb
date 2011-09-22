require 'test/helper'

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    Artifice.activate_with(KensaServer.new)
    @data = Manifest.new.skeleton
    @data['api']['password'] = 'secret'
  end

  teardown do
    Artifice.deactivate
  end

  def check ; ProvisionCheck ; end

  test "working provision call" do
    @data['api']['test'] += "working"
    assert_valid
  end

  test "allows the definition of a custom provisioning endpoint" do
    Artifice.activate_with(KensaServer.new)
    @data['api']['test'] = {
      "base_url" => "https://example.org/providers/provision",
      "sso_url"  => "https://example.org/sso"
    }
    assert_valid
  end

  test "detects invalid JSON" do
    @data['api']['test'] += "invalid-json"
    assert_invalid
  end

  test "detects invalid response" do
    @data['api']['test'] += "invalid-response"
    assert_invalid
  end

  test "detects invalid status" do
    @data['api']['test'] += "invalid-status"
    assert_invalid
  end

  test "detects missing id" do
    @data['api']['test'] += "invalid-missing-id"
    assert_invalid
  end

  test "detects missing auth" do
    @data['api']['test'] += "invalid-missing-auth"
    assert_invalid
  end

end
