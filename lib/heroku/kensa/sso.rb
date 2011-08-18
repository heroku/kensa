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
        @use_post = data[:post]
        run_proxy if data[:post]
      end

      def path
        "/heroku/resources/#{id}"
      end

      def full_url
        if @use_post
          "http://localhost:#{@proxy_port}/"
        else
          [ url, path, querystring ].join
        end
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

      def run_proxy
        @proxy_port = 9999
        begin
          params = { :port => @proxy_port, :host => url, :id => @id }
          t = Time.now.to_i
          params.merge! :token => make_token(t), :timestamp => t, 'nav-data' => sample_nav_data if @salt
          server = PostProxy.new params
        rescue Errno::EADDRINUSE
          @proxy_port -= 1
          retry
        end

        trap("INT") { server.stop }
        pid = fork do
          server.start 
        end
        at_exit { server.stop; Process.waitpid pid }
      end
    end
  end
end
