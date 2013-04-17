require 'restclient'
require 'uri'

module Heroku
  module Kensa
    class Sso
      attr_accessor :id, :url, :proxy_port, :timestamp, :token

      def initialize(data)
        @id   = data[:id]
        @salt = data['api']['sso_salt']

        env   = data.fetch :env, 'test'
        @proxy_port = find_available_port
        @timestamp  = Time.now.to_i
        @token      = make_token(@timestamp)
      end

      def path
        URI.parse(url).path
      end

      def sso_url
        "http://localhost:#{@proxy_port}/"
      end

      def full_url
        sso_url
      end

      def post_url
        url
      end

      def timestamp=(other)
        @timestamp = other
        @token = make_token(@timestamp)
      end

      def make_token(t)
        Digest::SHA1.hexdigest([@id, @salt, t].join(':'))
      end

      def query_data
        query_params.map{|p| p.join('=')}.join('&')
      end

      def query_params
        { 'token'     => @token,
          'timestamp' => @timestamp.to_s,
          'nav-data'  => sample_nav_data,
          'email'     => 'username@example.com',
          'id'        => @id }
      end

      def sample_nav_data
        json = OkJson.encode({
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

      def message
        "POSTing #{query_data} to #{post_url} via proxy on port #{@proxy_port}"
      end

      def start
        run_proxy
        self
      end

      def find_available_port
        server = TCPServer.new('127.0.0.1', 0)
        server.addr[1]
      ensure
        server.close if server
      end

      def run_proxy
        server = PostProxy.new self
        @proxy = server

        trap("INT") { server.stop }
        pid = fork do
          server.start
        end
        at_exit { server.stop; Process.waitpid pid }
      end
    end
  end
end
