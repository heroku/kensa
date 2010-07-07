module Heroku
  module Kensa
    module Manifest

      def self.init(filename)
        open(filename, 'w') {|f| f << skeleton_str }
      end

      def self.skeleton
        Yajl::Parser.parse(skeleton_str)
      end

      def self.skeleton_str
        return <<EOJSON
{
  "id": "myaddon",
  "name": "My Addon",
  "plans": [
    {
      "id": "basic",
      "name": "Basic",
      "price": "0",
      "price_unit": "month"
    }
  ],
  "api": {
    "config_vars": [
      "MYADDON_URL"
    ],
    "production": "https://yourapp.com/",
    "test": "http://localhost:4567/",
    "username": "heroku",
    "password": "#{generate_password(16)}",
    "sso_salt": "#{generate_password(16)}"
  }
}
EOJSON
      end

      PasswordChars = chars = ['a'..'z', 'A'..'Z', '0'..'9'].map { |r| r.to_a }.flatten
      def self.generate_password(size=16)
        Array.new(size) { PasswordChars[rand(PasswordChars.size)] }.join
      end

    end
  end
end

