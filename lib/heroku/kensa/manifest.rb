module Heroku
  module Kensa
    class Manifest

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
    "default_config_var" : "MYADDON_URL",
    "password": "#{@password}",#{ sso_key }
    "production": "https://yourapp.com/",
    "test": "http://localhost:#{@port}/"
  }
}
JSON
      end

      def post_skeleton
        <<-JSON
{
  "id": "myaddon",
  "api": {
    "default_config_var" : "MYADDON_URL",
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

        PasswordChars = chars = ['a'..'z', 'A'..'Z', '0'..'9'].map { |r| r.to_a }.flatten
        def generate_password(size=16)
          Array.new(size) { PasswordChars[rand(PasswordChars.size)] }.join
        end

    end
  end
end

