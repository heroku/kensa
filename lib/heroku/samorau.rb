require 'yajl'
require 'restclient'
require 'socket'
require 'timeout'

module Heroku

  module Samorau

    module Manifest

      def self.init(filename)
        json = Yajl::Encoder.encode(skeleton, :pretty => true)
        open(filename, 'w') {|f| f << json }
      end

      def self.skeleton
        {
          "name" => "myaddon",

          "api" => {
            "username" => "heroku",
            "password" => generate_password,
            "test" => "http://localhost:4567/",
            "production" => "https://yourapp.com/",
            "config_vars" => ["MYADDON_URL"]
          },

          "plans" => [
            {
              "name" => "Basic",
              "price" => "0",
              "price_unit" => "month"
            }
          ]
        }
      end

      def self.generate_password
        Array.new(8) { rand(256) }.pack('C*').unpack('H*').first
      end

    end


    class NilScreen

      def test(msg)
      end

      def check(msg)
      end

      def error(msg)
      end

      def result(status)
      end

    end


    class Check
      attr_accessor :screen, :data

      class CheckError < StandardError ; end

      def initialize(data, screen=NilScreen.new)
        @data = data
        @screen = screen
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

    end


    class ManifestCheck < Check

      ValidPriceUnits = %w[month dyno_hour]

      def call!
        test "manifest name key"
        check "if exists" do
          data.has_key?("name")
        end
        check "is a string" do
          data["name"].is_a?(String)
        end
        check "is not blank" do
          !data["name"].empty?
        end

        test "manifest api key"
        check "if exists" do
          data.has_key?("api")
        end
        check "is a hash" do
          data["api"].is_a?(Hash)
        end
        check "contains username" do
          data["api"].has_key?("username") && data["api"]["username"] != ""
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
        check "production url uses SSL" do
          data["api"]["production"] =~ /^https:/
        end
        check "contains config_vars array" do
          data["api"].has_key?("config_vars") && data["api"]["config_vars"].is_a?(Array)
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

        test "plans"
        check "key must exist" do
          data.has_key?("plans")
        end
        check "is an array" do
          data["plans"].is_a?(Array)
        end
        check "contains at least one plan" do
          !data["plans"].empty?
        end
        check "all plans are a hash" do
          data["plans"].all? {|plan| plan.is_a?(Hash) }
        end
        check "all plans have a name" do
          data["plans"].all? {|plan| plan.has_key?("name") }
        end
        check "all plans have a unique name" do
          names = data["plans"].map {|plan| plan["name"] }
          names.size == names.uniq.size
        end

        data["plans"].each do |plan|
          check "#{plan["name"]} has a valid price" do
            if plan["price"] !~ /^\d+$/
              error "expected an integer"
            else
              true
            end
          end

          check "#{plan["name"]} has a valid price_unit" do
            if ValidPriceUnits.include?(plan["price_unit"])
              true
            else
              error "expected #{ValidPriceUnits.join(" or ")} but got #{plan["price_unit"].inspect}"
            end
          end
        end
      end

    end


    class CreateResponseCheck < Check

      def call!
        response = data[:create_response]
        test "response"
        check "contains an id" do
          response.has_key?("id")
        end

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

          check "all config values are strings" do
            response["config"].each do |k, v|
              if v.is_a?(String)
                true
              else
                error "#{v.inspect} is not a string"
              end
            end
          end
        end
      end

    end


    module HTTP

      def post(credentials, path, payload=nil)
        request(:post, credentials, path, payload)
      end

      def delete(credentials, path, payload=nil)
        request(:delete, credentials, path, payload)
      end

      def request(meth, credentials, path, payload=nil)
        code = nil
        body = nil

        begin
          args = [
            (Yajl::Encoder.encode(payload) if payload),
            {
              :accept => "application/json",
              :content_type => "application/json"
            }
          ].compact

          user, pass = credentials
          body = RestClient::Resource.new(url, user, pass)[path].send(
            meth,
            *args
          )

          code = 200
        rescue RestClient::ExceptionWithResponse => boom
          code = boom.http_code
          body = boom.http_body
        rescue Errno::ECONNREFUSED
          code = -1
          body = nil
        end

        [code, body]
      end

    end

    class ApiCheck < Check
      def url
        env = data[:env] || 'test'
        data["api"][env].chomp("/")
      end

      def credentials
         %w( username password ).map { |attr| data["api"][attr] }
      end
    end

    class CreateCheck < ApiCheck
      include HTTP

      READLEN = 1024 * 10
      APPID = "app123@heroku.com"

      def call!
        json = nil
        response = nil

        code = nil
        json = nil
        path = "/heroku/resources"
        callback = "http://localhost:7779/callback/999"
        reader, writer = nil

        payload = {
          :id => APPID,
          :plan => "Basic",
          :callback_url => callback
        }

        if data[:async]
          reader, writer = IO.pipe
        end

        test "POST /heroku/resources"
        check "response" do
          if data[:async]
            child = fork do
              Timeout.timeout(10) do
                reader.close
                server = TCPServer.open(7779)
                client = server.accept
                writer.write(client.readpartial(READLEN))
                client.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n")
                client.close
                writer.close
              end
            end
            sleep(1)
          end

          code, json = post(credentials, path, payload)

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
            response = Yajl::Parser.parse(json)
          rescue Yajl::ParseError => boom
            error boom.message
          end
          true
        end

        check "authentication" do
          wrong_credentials = ['wrong', 'secret']
          code, _ = post(wrong_credentials, path, payload)
          error("expected 401, got #{code}") if code != 401
          true
        end

        data[:create_response] = response

        run CreateResponseCheck, data
      end

    ensure
      reader.close rescue nil
      writer.close rescue nil
    end


    class DeleteCheck < ApiCheck
      include HTTP

      def call!
        id = data[:id]
        raise ArgumentError, "No id specified" if id.nil?

        path = "/heroku/resources/#{id}"

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
        run CreateCheck, data

        response = data[:create_response]
        id = response["id"]
        config = response["config"] || Hash.new

        if args
          screen.message "\n\n"
          screen.message "Starting #{args.first}..."
          screen.message ""

          run_in_env(config) { system(*args) }

          screen.message ""
          screen.message "End of #{args.first}"
        end

        run DeleteCheck, data.merge(:id => id)
      end

      def run_in_env(env)
        env.each {|key, value| ENV[key] = value }
        yield
        env.keys.each {|key| ENV.delete(key) }
      end

    end

  end

end
