require 'yajl'
require 'restclient'
require 'socket'

module Heroku

  module Vendor

    module Manifest

      def self.init(filename)
        json = Yajl::Encoder.encode(skeleton, :pretty => true)
        open(filename, 'w') {|f| f << json }
      end

      def self.skeleton
        {
          "name" => "youraddon",

          "api" => {
            "test" => "http://localhost:4567/",
            "production" => "https://yourapp.com/"
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
        check "contains test url" do
          data["api"].has_key?("test")
        end
        check "contains production url" do
          data["api"].has_key?("production")
        end
        check "production url uses SSL" do
          data["api"]["production"] =~ /^https:/
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
        test "response"
        check "contains an id" do
          data.has_key?("id")
        end

        if data.has_key?("config")
          test "config data"
          check "is a hash" do
            data["config"].is_a?(Hash)
          end

          check "all keys are uppercase strings" do
            data["config"].each do |k, v|
              if k =~ /^[A-Z][0-9A-Z_]*$/
                true
              else
                error "#{k.inspect} is not a valid ENV key"
              end
            end
          end

          check "all values are strings" do
            data["config"].each do |k, v|
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

      def post(path, payload=nil)
        request(:post, path, payload)
      end

      def delete(path, payload=nil)
        request(:delete, path, payload)
      end

      def request(meth, path, payload=nil)
        code = nil
        body = nil

        begin
          args = [
            @url + path,
            (Yajl::Encoder.encode(payload) if payload),
            {
              :accept => "application/json",
              :content_type => "application/json"
            }
          ].compact

          body = RestClient.send(
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


    class CreateCheck < Check
      include HTTP

      APPID = "app123@heroku.com"

      def call!
        @url = data["api"]["test"].chomp("/")

        json = nil
        response = nil

        test "POST /heroku/apps"

        check "response" do
          code = nil
          json = nil
          path = "/heroku/apps"
          child = nil
          callback = "http://localhost:7779/callback/999"

          payload = {
            :id => APPID,
            :plan => "Basic",
            :callback_url => callback
          }

          if data[:async]
            reader, writer = IO.pipe
            child = fork do
              reader.close
              server = TCPServer.open(7779)
              client = server.accept
              p :got_it
              d = client.read(256)
              writer.write(d)
              client.write("Status: 200\r\n\r\n")
              client.close
              p [:d, d]
              writer.close
            end
            # give it a chance to listen
            p :waiting_for_server
            sleep(1)
          end

          code, json = post(path, payload)

          if code == 200
            # noop
          elsif code == -1
            Process.kill(:INT, child) if child
            error("unable to connect to #{@url}")
          else
            Process.kill(:INT, child) if child
            error("expected 200, got #{code}")
          end

          if data[:async]
            p :waiting_for_response
            out = reader.read
            p :got_response
            if out =~ /^PUT \/callback\/999/
              json = out.split("\r\n\r\n").last
            else
              error "callback received invalid request"
            end
          end

          true

        end

        check "valid JSON" do
          begin
            response = Yajl::Parser.parse(json)
          rescue Yajl::ParseError => boom
            error boom.message
          end
          true
        end

        data[:create_response] = response

        run CreateResponseCheck, response
      end

    end


    class DeleteCheck < Check
      include HTTP

      def call!
        id = data[:id]
        raise ArgumentError, "No id specified" if id.nil?

        path = "/heroku/apps/#{id}"

        @url = data["api"]["test"].chomp("/")

        test "DELETE #{path}"
        check "response" do
          code, json = delete(path, nil)
          if code == 200
            true
          elsif code == -1
            error("unable to connect to #{@url}")
          else
            error("expected 200, got #{code}")
          end
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
          run_in_env(config) do
            screen.message "\n\n"
            screen.message "Starting #{args.first}..."
            screen.message ""
            system(*args)
            screen.message ""
            screen.message "End of #{args.first}"
          end
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
