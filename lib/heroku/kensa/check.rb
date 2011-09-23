require 'yajl'
require 'mechanize'
require 'socket'
require 'timeout'
require 'uri'

module Heroku
  module Kensa

    class NilScreen
      def test(msg)
      end

      def check(msg)
      end

      def error(msg)
      end

      def result(status)
      end

      def message(msg)
      end
    end

    class STDOUTScreen
      [:test, :check, :error, :result, :message].each do |method|
        eval %{ def #{method}(*args)\n STDOUT.puts *args\n end }
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

    ##
    # On Testing:
    #  I've opted to not write tests for this
    #  due to the simple nature it's currently in.
    #  If this becomes more complex in even the
    #  least amount, find me (blake) and I'll
    #  help get tests in.
    class AllCheck < Check

      def call!
        screen.message "Running all :( \n\n"
        args = data[:args]
        #run ProvisionCheck, data

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

        #run DeprovisionCheck, data
      end

      def run_in_env(env)
        env.each {|key, value| ENV[key] = value }
        yield
        env.keys.each {|key| ENV.delete(key) }
      end

    end

  end
end
