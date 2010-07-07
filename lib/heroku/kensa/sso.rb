require 'restclient'

module Heroku
  module Kensa
    class Sso
      attr_accessor :id, :url

      def initialize(data)
        @id   = data[:id]
        @salt = data['api']['sso_salt']
        env   = data[:env] || 'test'
        @url  = data["api"][env].chomp('/')
      end

      def path
        "/heroku/resources/#{id}"
      end

      def full_url
        [ url, path, token_querystring ].join
      end

      def make_token(t)
        Digest::SHA1.hexdigest([@id, @salt, t].join(':'))
      end

      private

        def token_querystring
          return '' unless @salt

          t = Time.now.to_i
          "?token=#{make_token(t)}&timestamp=#{t}"
        end

    end
  end
end
