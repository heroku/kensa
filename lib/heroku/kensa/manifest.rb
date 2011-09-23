module Heroku
  module Kensa
    class Manifest

      def initialize(filename = 'addon-manifest.json', options = {})
        @filename, @options = filename, options
      end

      def skeleton_json
        <<-JSON
{
  "id": "myaddon",
  "api": {
    "config_vars": [ "MYADDON_USER", "MYADDON_URL" ],
    "password": "#{generate_password(16)}",#{ sso_key }
    "production": {
      "base_url": "https://yourapp.com/heroku/resources",
      "sso_url": "https://yourapp.com/sso/login"
    },
    "test": {
      "base_url": "http://localhost:4567/heroku/resources",
      "sso_url": "http://localhost:4567/sso/login"
    }
  }
}
JSON
      end

      def skeleton
        Yajl::Parser.parse skeleton_json
      end

      def write
        open(@filename, 'w') { |f| f << skeleton_json }
      end

      private

        def sso_key
          unless @options[:sso] === false
            %{\n    "sso_salt": #{ generate_password(16).inspect },}
          end
        end

        PasswordChars = chars = ['a'..'z', 'A'..'Z', '0'..'9'].map { |r| r.to_a }.flatten
        def generate_password(size=16)
          Array.new(size) { PasswordChars[rand(PasswordChars.size)] }.join
        end

    end
  end
end

