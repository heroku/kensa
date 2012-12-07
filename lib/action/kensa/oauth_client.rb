require File.expand_path(File.dirname(__FILE__) + '/../../../config/settings')
require 'oauth2'
require 'netrc'

module Action
  module Kensa
    class OauthClient
      SCOPES = 'addons'
      API_PATHS_PREFIX = '/api/v0'

      def initialize(options={})
        oauth_options = { site: AIOSettings.oauth_host }.merge(options)
        ssl_options = { ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
        oauth_options.merge!(ssl_options) if AIOSettings.env == 'development'
        @client  = OAuth2::Client.new(AIOSettings.oauth_client_id,
                                      AIOSettings.oauth_client_secret,
                                      oauth_options)
        @nrc = Netrc.read
      end

      def access_token
        if @_access_token.nil?
          username, token = @nrc['action.io']
          @_access_token = OAuth2::AccessToken.new(@client, token)
        end
        @_access_token
      end

      def username
        @_username, token = @nrc['action.io'] if @_username.nil?
        @_username
      end

      def authenticated?
        !@nrc['action.io'].nil?
      end

      def authenticate!(username, password)
        token = obtain_access_token(username, password)
        save_access_token(username, token) if token
      end

      def request(verb, path, options={})
        request_options = { parse: :json }.merge(options)
        response = access_token.request(verb.to_sym,
                                        path,
                                        request_options)
      end

      protected

      def save_access_token(username, token)
        @_username, @_access_token = username, token
        @nrc['action.io'] = @_username, @_access_token.token
        @nrc.save
      end

      def obtain_access_token(username, password)
        @client.password.get_token(username, password, mode: :json, scope: SCOPES)

      rescue OAuth2::Error => err
        if err.response.status == '401'
          @_access_token = nil
        else
          raise err
        end
      end

    end # OauthClient
  end # Kensa
end # Action
