require './test/helper'

class OauthClientTest < Test::Unit::TestCase
  include Action::Kensa

  context 'authenticated?' do
    context 'when there is no .netrc' do
      setup do
        stub(Netrc).read { {} }
        @oauth_client = Action::Kensa::OauthClient.new
      end

      test 'should return false' do
        assert_equal false, @oauth_client.authenticated?
      end
    end

    context 'when there is a .netrc but no entry' do
      setup do
        stub(Netrc).read { {'action.oi' => 'foo' } }
        @oauth_client = Action::Kensa::OauthClient.new
      end

      test 'should return false' do
        assert_equal false, @oauth_client.authenticated?
      end
    end

    context 'when there is a .netrc with an entry' do
      setup do
        stub(Netrc).read { {'action.io' => 'foo' } }
        @oauth_client = Action::Kensa::OauthClient.new
      end

      test 'should return true' do
        assert_equal true, @oauth_client.authenticated?
      end
    end
  end

  context 'authenticate!' do
    context 'when the request for token is successful' do
      setup do
        mock_token = Object.new
        mock(mock_token).token { 'foo' }
        mock_strategy = Object.new
        mock(mock_strategy).get_token('foo', 'bar', {mode: :json, scope: 'addons'}) { mock_token }
        any_instance_of(OAuth2::Client) do |c|
          stub(c).password { mock_strategy }
        end

        @action_netrc = Object.new
        mock(@action_netrc).save
        mock(@action_netrc).[]=('action.io', ['foo', 'foo'])
        stub(Netrc).read { @action_netrc }
        @oauth_client = Action::Kensa::OauthClient.new
      end

      test 'should save the access token' do
        @oauth_client.authenticate!('foo', 'bar')
      end
    end

    context 'when the request for token is not successful' do
      setup do
        mock_strategy = Object.new
        stub(mock_strategy).get_token('foo', 'bar', {mode: :json, scope: 'addons'}) do
          nil
        end
        any_instance_of(OAuth2::Client) do |c|
          stub(c).password { mock_strategy }
        end

        @action_netrc = Object.new
        dont_allow(@action_netrc).save
        dont_allow(@action_netrc).[]=('action.io', ['foo', 'foo'])
        stub(Netrc).read { @action_netrc }
        @oauth_client = Action::Kensa::OauthClient.new
      end

      test 'should not save the access token' do
        @oauth_client.authenticate!('foo', 'bar')
      end
    end
  end

  context 'access_token' do
    setup do
      stub(Netrc).read { {'action.io' => 'foo' } }
      @oauth_client = Action::Kensa::OauthClient.new
    end

    test 'should return the access token' do
      assert @oauth_client.access_token.is_a? OAuth2::AccessToken
    end
  end

  context 'username' do
    setup do
      stub(Netrc).read { {'action.io' => 'foo' } }
      @oauth_client = Action::Kensa::OauthClient.new
    end

    test 'should return the username' do
      assert @oauth_client.username.is_a? String
    end
  end
end
