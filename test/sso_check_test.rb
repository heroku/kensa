require 'test/helper'

class SsoCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    Timecop.freeze Time.now.utc
    @data = Manifest.new.skeleton.merge :id => 123
    @data['api']['sso_salt'] = 'SSO_SALT'
  end

  teardown do
    Timecop.return
    Artifice.deactivate
  end

  def check ; SsoCheck ; end

  context "via GET" do
    setup do
      Artifice.activate_with(KensaServer.new)
      @data['api']['sso'] = "GET"
    end

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

    test "reject missing heroku layout" do
      @data['api']['test'] += "nolayout"
      assert_invalid
    end

    test "reject missing cookie" do
      @data['api']['test'] += "nocookie"
      assert_invalid
    end

    test "reject invalid cookie value" do
      @data['api']['test'] += "badcookie"
      assert_invalid
    end

    test "sends user param" do
      @data['api']['test'] += "user"
      assert_valid
    end
  end

  context "via POST" do
    setup { @data['api']['sso'] = "POST" }

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

    test "reject missing heroku layout" do
      @data['api']['test'] += "nolayout"
      assert_invalid
    end

    test "reject missing cookie" do
      @data['api']['test'] += "nocookie"
      assert_invalid
    end

    test "reject invalid cookie value" do
      @data['api']['test'] += "badcookie"
      assert_invalid
    end

    test "sends user param" do
      @data['api']['test'] += "user"
      assert_valid
    end
  end
end
