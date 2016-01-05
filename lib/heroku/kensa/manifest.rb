require 'securerandom'

module Heroku
  module Kensa
    class Manifest
      REGIONS = %w(us eu frankfurt oregon tokyo virginia *)

      def initialize(options = {})
        @method   = options.fetch(:method, 'post').to_sym
        @filename = options[:filename]
        @options  = options
      end

      def skeleton_json
        @password = generate_password(16)
        @port     = @options[:foreman] ? 5000 : 4567
        (@method == :get) ? get_skeleton : post_skeleton
      end

      def get_skeleton
        <<-JSON
{
  "id": "myaddon",
  "api": {
    "config_vars": [ "MYADDON_URL" ],
    "regions": [ "us" ],
    "password": "#{@password}",#{ sso_key }
    "production": "https://yourapp.com/",
    "test": "http://localhost:#{@port}/",
    "requires": []
  }
}
JSON
      end

      def post_skeleton
        <<-JSON
{
  "id": "myaddon",
  "api": {
    "config_vars": [ "MYADDON_URL" ],
    "requires": [],
    "regions": [ "us" ],
    "password": "#{@password}",#{ sso_key }
    "production": {
      "base_url": "https://yourapp.com/heroku/resources",
      "sso_url": "https://yourapp.com/sso/login"
    },
    "test": {
      "base_url": "http://localhost:#{@port}/heroku/resources",
      "sso_url": "http://localhost:#{@port}/sso/login"
    }
  }
}
JSON

      end

      def foreman
        <<-ENV
SSO_SALT=#{@sso_salt}
HEROKU_USERNAME=myaddon
HEROKU_PASSWORD=#{@password}
ENV
      end

      def skeleton
        OkJson.decode skeleton_json
      end

      def write
        File.open(@filename, 'w') { |f| f << skeleton_json }
        File.open('.env', 'w') { |f| f << foreman } if @options[:foreman]
      end

      private

        def sso_key
          @sso_salt = generate_password(16)
          unless @options[:sso] === false
            %{\n    "sso_salt": "#{@sso_salt}",}
          end
        end

        def generate_password(size=8)
          SecureRandom.hex(size)
        end

    end
  end
end

