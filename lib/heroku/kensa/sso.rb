require 'restclient'

module Heroku
  module Kensa
    class Sso
      attr_accessor :id, :url, :proxy_port, :timestamp, :token

      def initialize(data)
        @id   = data[:id]
        @salt = data['api']['sso_salt']

        env   = data.fetch :env, 'test'
        if data["api"][env].is_a?(Hash)
          @url  = data["api"][env]["base_url"].chomp('/')
          @use_post = true
        else
          @url  = data["api"][env].chomp('/')
          @use_post = false
        end
        @proxy_port = find_available_port
        @timestamp  = Time.now.to_i
        @token      = make_token(@timestamp)
      end

      def path
        extra = self.POST? ? '/sso' : ''
        "/heroku/resources/#{id}#{extra}"
      end

      def POST?
        @use_post
      end

      def sso_url
        if self.POST?
          "http://localhost:#{@proxy_port}/"
        else
          full_url
        end
      end

      def full_url
        [ url, path, querystring ].join
      end
      alias get_url full_url

      def post_url
        [ url, path ].join
      end

      def timestamp=(other)
        @timestamp = other
        @token = make_token(@timestamp)
      end

      def make_token(t)
        Digest::SHA1.hexdigest([@id, @salt, t].join(':'))
      end

      def querystring
        return '' unless @salt
        '?' + query_data
      end

      def query_data
        query_params.map{|p| p.join('=')}.join('&')
      end

      def query_params
        { 'token' => @token,
          'timestamp' => @timestamp.to_s,
          'nav-data' => sample_nav_data,
          'user'     => 'username@example.com' }
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

      def message
        if self.POST?
          "POSTing #{query_data} to #{post_url} via proxy on port #{@proxy_port}"
        else
          "Opening #{full_url}"
        end
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
        return unless self.POST?
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
