require 'restclient'

module Heroku
  module Kensa
    class Sso
      attr_accessor :id, :url

      def initialize(data)
        @id   = data[:id]
        @salt = data['api']['sso_salt']

        env   = data.fetch :env, 'test'
        @url  = data["api"][env].chomp('/')
      end

      def path
        "/heroku/resources/#{id}"
      end

      def full_url
        [ url, path, querystring ].join
      end

      def make_token(t)
        Digest::SHA1.hexdigest([@id, @salt, t].join(':'))
      end

      def querystring
        return '' unless @salt

        t = Time.now.to_i
        "?token=#{make_token(t)}&timestamp=#{t}&nav-data=#{sample_nav_data}"
      end

      def sample_nav_data
        json = Yajl::Encoder.encode({
          :addon => 'Your Addon',
          :appname => 'myapp',
          :addons => [
            { :slug => 'cron', :name => 'Cron' },
            { :slug => 'custom_domains+wildcard', :name => 'Custom Domains + Wildcard' },
            { :slug => 'youraddon', :name => 'Your Addon', :current => true },
          ]
        })
        base64_url_variant(json)
      end

      def base64_url_variant(text)
        base64 = [text].pack('m').gsub('=', '').gsub("\n", '')
        base64.tr('+/','-_')
      end

    end
  end
end
