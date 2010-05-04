require File.dirname(__FILE__) + "/helper"

class ProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Sensei

  setup do
    @data = Manifest.skeleton
    @data['api']['username'] = 'test'
    @data['api']['password'] = 'secret'
  end

  def check ; ProvisionCheck ; end

  test "working provision call" do
    @data['api']['test'] += "working"
    assert_valid
  end

  test "detects invalid JSON" do
    @data['api']['test'] += "invalid-json"
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
