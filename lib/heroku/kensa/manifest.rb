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
    "config_vars": [ "MYADDON_URL" ],
    "username": "heroku",
    "password": "b1EWrHYXE1R5J71D",#{ sso_key }
    "production": "https://yourapp.com/",
    "test": "http://localhost:4567/"
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

