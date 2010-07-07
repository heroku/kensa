module Heroku
  module Kensa
    class Manifest

      def initialize(filename = 'addon-manifest.json', options = {})
        @filename, @options = filename, options
      end

      def skeleton
        response = {
          'id'    => 'myaddon',
          'name'  => 'My Addon',
          'plans' => [{
            'id'          => 'basic',
            'name'        => 'Basic',
            'price'       => '0',
            'price_unit'  => 'month'
          }],
          'api' => {
            'config_vars' => [ 'MYADDON_URL' ],
            'production'  => 'https://yourapp.com/',
            'test'        => 'http://localhost:4567/',
            'username'    => 'heroku',
            'password'    => generate_password(16)
          }
        }

        unless @options[:sso] === false
          response['api']['sso_salt'] = generate_password 16
        end

        response
      end

      # I thought it would be easier to convert #skeleton to a hash and use Yajl
      # to encode it as a string here, but then you lose control over organizing
      # keys in a logical manner.
      def skeleton_str
        Yajl::Encoder.encode skeleton, :pretty => true
      end

      def write
        open(@filename, 'w') { |f| f << skeleton_str }
      end

      PasswordChars = chars = ['a'..'z', 'A'..'Z', '0'..'9'].map { |r| r.to_a }.flatten
      def generate_password(size=16)
        Array.new(size) { PasswordChars[rand(PasswordChars.size)] }.join
      end

    end
  end
end

