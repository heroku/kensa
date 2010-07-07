require 'test/helper'

class SsoCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @data = Manifest.new.skeleton.merge :id => 123
    @data['api']['sso_salt'] = 'SSO_SALT'
  end

  def check ; SsoCheck ; end

  test "working sso request" do
    @data['api']['test'] += "working"
    assert_valid
  end

  test "rejects bad token" do
    @data['api']['test'] += "notoken"
    assert_invalid
  end

  test "rejects old timestamp" do
    @data['api']['test'] += "notimestamp"
    assert_invalid
  end

  test "reject omitted sso salt" do
    @data['api'].delete 'sso_salt'
    @data['api']['test'] += "working"

    assert_invalid
  end

end
