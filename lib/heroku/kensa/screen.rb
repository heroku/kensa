module Heroku
  module Kensa

    class NilScreen
      def test(msg)
      end

      def check(msg)
      end

      def error(msg)
      end

      def warning(msg)
      end

      def result(status)
      end

      def message(msg)
      end

      def finish
      end
    end

    class IOScreen
      attr_accessor :output

      def initialize(io)
        @output = io
      end

      def to_s
        @output.closed_read? ? '' : @output.tap{|o| o.rewind }.read
      end

      [:test, :check, :error, :result, :message].each do |method|
        eval %{ def #{method}(*args)\n @output.puts *args\n end }
      end
    end
  end
end
