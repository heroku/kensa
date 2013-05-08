require 'test/helper'

class SsoCheckTest < MiniTest::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock

  def check ; SsoCheck ; end
  %w{get post}.each do |method|
    context "via #{method}" do
      setup do
        @data = Manifest.new(:sso => true, :method => method).
          skeleton.merge :id => 123
        @data['api']['sso_salt'] = 'SSO_SALT'
      end

      test "working sso request" do
        pending "Need to re-implement"
        use_provider_endpoint('working', 'sso')
        assert_valid
      end

      test "rejects bad token" do
        pending "Need to re-implement"
        use_provider_endpoint("notoken", 'sso')
        assert_invalid
      end

      test "rejects old timestamp" do
        pending "Need to re-implement"
        use_provider_endpoint("notimestamp", 'sso')
        assert_invalid
      end

      test "reject omitted sso salt" do
        pending "Need to re-implement"
        @data['api'].delete 'sso_salt'
        use_provider_endpoint("working", 'sso')
        assert_invalid
      end

      test "reject missing heroku layout" do
        pending "Need to re-implement"
        use_provider_endpoint("nolayout", 'sso')
        assert_invalid
      end

      test "reject missing cookie" do
        pending "Need to re-implement"
        use_provider_endpoint("nocookie", 'sso')
        assert_invalid
      end

      test "reject invalid cookie value" do
        pending "Need to re-implement"
        use_provider_endpoint("badcookie", 'sso')
        assert_invalid
      end

      test "sends email param" do
        pending "Need to re-implement"
        use_provider_endpoint("user", 'sso')
        assert_valid
      end
    end
  end
end
