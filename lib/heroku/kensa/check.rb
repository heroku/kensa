require 'mechanize'
require 'socket'
require 'timeout'
require 'uri'

module Heroku
  module Kensa
    class Check
      attr_accessor :screen, :data

      class CheckError < StandardError ; end

      def initialize(data, screen=NilScreen.new)
        @data = data
        @screen = screen
      end

      def env
        @data.fetch(:env, 'test')
      end

      def test(msg)
        screen.test msg
      end

      def check(msg)
        screen.check(msg)
        if yield
          screen.result(true)
        else
          raise CheckError
        end
      end

      def run(klass, data)
        c = klass.new(data, screen)
        instance_eval(&c)
      end

      def error(msg)
        raise CheckError, msg
      end

      def call
        call!
        true
      rescue CheckError => boom
        screen.result(false)
        screen.error boom.message if boom.message != boom.class.name

        false
      end

      def to_proc
        me = self
        Proc.new { me.call! }
      end

      def url
        if data['api'][env].is_a? Hash
          base = data['api'][env]['base_url']
          uri = URI.parse(base)
          base.sub!(uri.query, '') if uri.query
          base.sub(uri.path, '')
        else
          data['api'][env].chomp("/")
        end
      end
    end


    class ManifestCheck < Check

      ValidPriceUnits = %w[month dyno_hour]

      def call!
        test "manifest id key"
        check "if exists" do
          data.has_key?("id")
        end
        check "is a string" do
          data["id"].is_a?(String)
        end
        check "is not blank" do
          !data["id"].empty?
        end

        test "manifest api key"
        check "if exists" do
          data.has_key?("api")
        end
        check "is a hash" do
          data["api"].is_a?(Hash)
        end
        check "has a list of regions" do
          data["api"].has_key?("regions")
          data["api"]["regions"].is_a?(Array)
        end
        check "contains at least the US region" do
          data["api"]["regions"].include? "us"
        end
        check "contains only valid region names" do
          data["api"]["regions"].all? { |reg| Manifest::REGIONS.include? reg }
        end
        check "contains password" do
          data["api"].has_key?("password") && data["api"]["password"] != ""
        end
        check "contains test url" do
          data["api"].has_key?("test")
        end
        check "contains production url" do
          data["api"].has_key?("production")
        end

        if data['api']['production'].is_a? Hash
          check "production url uses SSL" do
            data['api']['production']['base_url'] =~ /^https:/
          end
          check "sso url uses SSL" do
            data['api']['production']['sso_url'] =~ /^https:/
          end
        else
          check "production url uses SSL" do
            data['api']['production'] =~ /^https:/
          end
        end

        if data["api"].has_key?("config_vars") 
          check "contains config_vars array" do
            data["api"]["config_vars"].is_a?(Array)
          end
          check "containst at least one config var" do
            !data["api"]["config_vars"].empty?
          end
          check "all config vars are uppercase strings" do
            data["api"]["config_vars"].each do |k, v|
              if k =~ /^[A-Z][0-9A-Z_]+$/
                true
              else
                error "#{k.inspect} is not a valid ENV key"
              end
            end
          end
          check "all config vars are prefixed with the addon id" do
            data["api"]["config_vars"].each do |k|
              addon_key = data['id'].upcase.gsub('-', '_')
              if k =~ /^#{addon_key}_/
                true
              else
                error "#{k} is not a valid ENV key - must be prefixed with #{addon_key}_"
              end
            end
          end
        end

        check "deprecated fields" do
          if data["api"].has_key?("username")
            error "username is deprecated: Please authenticate using the add-on id."
          end
          true
        end
      end
    end


    class ProvisionResponseCheck < Check

      def call!
        response = data[:provision_response]
        test "response"

        check "contains an id" do
          response.is_a?(Hash) && response.has_key?("id")
        end

        screen.message " (id #{response['id']})"

        if response.has_key?("config")
          test "config data"
          check "is a hash" do
            response["config"].is_a?(Hash)
          end

          check "all config keys were previously defined in the manifest" do
            response["config"].keys.each do |key|
              error "#{key} is not in the manifest" unless data["api"]["config_vars"].include?(key)
            end
            true
          end

          check "all keys in the manifest are present" do
            difference = data['api']['config_vars'] - response['config'].keys 
            unless difference.empty?
              verb = (difference.size == 1) ? "is" : "are"
              error "#{difference.join(', ')} #{verb} missing from the manifest"
            end
            true
          end

          check "all config values are strings" do
            response["config"].each do |k, v|
              if v.is_a?(String)
                true
              else
                error "the key #{k} doesn't contain a string (#{v.inspect})"
              end
            end
          end

          check "URL configs vars" do
            response["config"].each do |key, value|
              next unless key =~ /_URL$/
              begin
                uri = URI.parse(value)
                error "#{value} is not a valid URI - missing host" unless uri.host
                error "#{value} is not a valid URI - missing scheme" unless uri.scheme
                error "#{value} is not a valid URI - pointing to localhost" if env == 'production' && uri.host == 'localhost'
              rescue URI::Error
                error "#{value} is not a valid URI"
              end
            end
          end

        end
      end

    end


    class ApiCheck < Check
      def base_path
        if data['api'][env].is_a? Hash
          URI.parse(data['api'][env]['base_url']).path
        else
          '/heroku/resources'
        end
      end

      def upstream_id
        "app#{rand(10000)}@kensa.#{upstream}.com"
      end

      def upstream_id_key
        :"#{upstream}_id"
      end

      def upstream
        data[:upstream] || "heroku"
      end

      def credentials
        [ data['id'], data['api']['password'] ]
      end
    end

    class ProvisionCheck < ApiCheck
      include HTTP

      READLEN = 1024 * 10

      def call!
        json = nil
        response = nil

        code = nil
        json = nil
        callback = "http://localhost:7779/callback/999"
        reader, writer = nil

        payload = {
          upstream_id_key => upstream_id,
          :plan => data[:plan] || 'test',
          :callback_url => callback, 
          :logplex_token => nil,
          :options => data[:options] || {}
        }

        if data[:async]
          reader, writer = IO.pipe
        end

        test "POST /heroku/resources"
        check "response" do
          if data[:async]
            child = fork do
              reader.close
              server = TCPServer.open(7779)
              client = server.accept
              writer.write(client.readpartial(READLEN))
              client.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n")
              client.close
              writer.close
            end
            sleep(1)
          end

          code, json = post(credentials, base_path, payload)

          if code == 200
            # noop
          elsif code == -1
            error("unable to connect to #{url}")
          else
            error("expected 200, got #{code}")
          end

          true
        end

        if data[:async]
          check "async response to PUT #{callback}" do
            out = reader.readpartial(READLEN)
            _, json = out.split("\r\n\r\n")
          end
        end

        check "valid JSON" do
          begin
            response = OkJson.decode(json)
          rescue OkJson::Error => boom
            error boom.message
          rescue NoMethodError => boom
            error "error parsing JSON"
          end
          true
        end

        check "authentication" do
          wrong_credentials = ['wrong', 'secret']
          code, _ = post(wrong_credentials, base_path, payload)
          error("expected 401, got #{code}") if code != 401
          true
        end

        data[:provision_response] = response

        run ProvisionResponseCheck, data
      end

    ensure
      reader.close rescue nil
      writer.close rescue nil
    end


    class DeprovisionCheck < ApiCheck
      include HTTP

      def call!
        id = data[:id]
        raise ArgumentError, "No id specified" if id.nil?

        path = "#{base_path}/#{CGI::escape(id.to_s)}"

        test "DELETE #{path}"
        check "response" do
          code, _ = delete(credentials, path, nil)
          if code == 200
            true
          elsif code == -1
            error("unable to connect to #{url}")
          else
            error("expected 200, got #{code}")
          end
        end

        check "authentication" do
          wrong_credentials = ['wrong', 'secret']
          code, _ = delete(wrong_credentials, path, nil)
          error("expected 401, got #{code}") if code != 401
          true
        end

      end

    end


    class PlanChangeCheck < ApiCheck
      include HTTP

      def call!
        id = data[:id]
        raise ArgumentError, "No id specified" if id.nil?

        new_plan = data[:plan]
        raise ArgumentError, "No plan specified" if new_plan.nil?

        path = "#{base_path}/#{CGI::escape(id.to_s)}"
        payload = {:plan => new_plan, upstream_id_key => upstream_id}

        test "PUT #{path}"
        check "response" do
          code, _ = put(credentials, path, payload)
          if code == 200
            true
          elsif code == -1
            error("unable to connect to #{url}")
          else
            error("expected 200, got #{code}")
          end
        end

        check "authentication" do
          wrong_credentials = ['wrong', 'secret']
          code, _ = put(wrong_credentials, path, payload)
          error("expected 401, got #{code}") if code != 401
          true
        end
      end
    end


    class SsoCheck < ApiCheck
      include HTTP

      def agent
        @agent ||= Mechanize.new
      end

      def mechanize_get
        if @sso.POST?
          page = agent.post(@sso.post_url, @sso.query_params)
        else
          page = agent.get(@sso.get_url)
        end
        return page, 200
      rescue Mechanize::ResponseCodeError => error
        return nil, error.response_code.to_i
      rescue Errno::ECONNREFUSED
        error("connection refused to #{url}")
      end

      def check(msg)
        @sso = Sso.new(data)
        super
      end

      def call!
        error("need an sso salt to perform sso test") unless data['api']['sso_salt']

        sso  = Sso.new(data)
        verb = sso.POST? ? 'POST' : 'GET'
        test "#{verb} #{sso.path}"

        check "validates token" do
          @sso.token = 'invalid'
          page, respcode = mechanize_get 
          error("expected 403, got #{respcode}") unless respcode == 403
          true
        end

        check "validates timestamp" do
          @sso.timestamp = (Time.now - 60*6).to_i
          page, respcode = mechanize_get
          error("expected 403, got #{respcode}") unless respcode == 403
          true
        end

        page_logged_in = nil
        check "logs in" do
          page_logged_in, respcode = mechanize_get 
          error("expected 200, got #{respcode}") unless respcode == 200
          true
        end

        check "creates the heroku-nav-data cookie" do
          cookie = agent.cookie_jar.cookies(URI.parse(@sso.full_url)).detect { |c| c.name == 'heroku-nav-data' }
          error("could not find cookie heroku-nav-data") unless cookie
          error("expected #{@sso.sample_nav_data}, got #{cookie.value}") unless cookie.value == @sso.sample_nav_data
          true
        end

        check "displays the heroku layout" do
            if page_logged_in.search('div#heroku-header').empty? &&
              page_logged_in.search('script[src*=boomerang]').empty?
              error("could not find Heroku layout")
            end
          true
        end
      end
    end


    ##
    # On Testing:
    #  I've opted to not write tests for this
    #  due to the simple nature it's currently in.
    #  If this becomes more complex in even the
    #  least amount, find me (blake) and I'll
    #  help get tests in.
    class AllCheck < Check

      def call!
        args = data[:args]
        run ProvisionCheck, data

        response = data[:provision_response]
        data.merge!(:id => response["id"])
        config = response["config"] || Hash.new

        if args
          screen.message "\n\n"
          screen.message "Starting #{args.first}..."
          screen.message "\n\n"

          run_in_env(config) { system(*args) }
          error("run exited abnormally, expected 0, got #{$?.to_i}") unless $?.to_i == 0

          screen.message "\n"
          screen.message "End of #{args.first}\n"
        end

        data[:plan] ||= 'foo'
        run PlanChangeCheck, data
        run DeprovisionCheck, data
      end

      def run_in_env(env)
        env.each {|key, value| ENV[key] = value }
        yield
        env.keys.each {|key| ENV.delete(key) }
      end

    end

  end
end
