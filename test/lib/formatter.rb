require 'test/unit'
require 'test/unit/ui/console/testrunner'

def format_kensa_test_name(name)
  name.sub(/\Atest_/,"").match(/\A([^\(]*)/)[1].gsub("_", " ")
end

module Test
  module Unit
    class TestCase
      alias_method :add_error_with_connection_exception, :add_error
      alias_method :add_failure_with_connection_exception, :add_failure

      private
      def add_error(exception)
        if exception.class == Errno::ECONNREFUSED
          @test_passed = false
          message = "Unable to connect to your API."
          @_result.add_failure(Failure.new(name, filter_backtrace(caller()), message))
        else
          add_error_with_connection_exception(exception)
        end
      end
    end

    class Failure
      def long_display
        name = format_kensa_test_name(@test_name)
        "#{name} - FAILED: #@message"
      end
    end

    class Error
      def long_display
        backtrace = filter_backtrace(@exception.backtrace).join("\n    ")
        name = format_kensa_test_name(@test_name)
        "#{@exception.class.name} in #{name}:\n#{message}\n    #{backtrace}"
      end
    end

    module UI
      module Console
        class TestRunner

          alias_method :test_started_old, :test_started

          def add_fault(fault)
            @faults << fault
            @already_outputted = true
          end

          def test_started(name)
            if name =~ /\((.*)::([^\)]*)/
              ctx, should = [$1, $2]
            end
            unless ctx.nil? or should.nil?
              if ctx != @ctx
                nl
                output("#{ctx}:")
              end
              @ctx = ctx
              @current_test_text = " ==> #{should}"
            else
              test_started_old(name)
            end
          end

          def test_finished(name)
            @current_test_text = name.sub(/\Atest_/,"").match(/\A([^\(]*)/)[1].gsub("_", " ")
            if fault = @faults.find {|f| f.test_name == name}
              fault_type = fault.is_a?(Test::Unit::Failure) ? "FAILED" : "ERROR!"
              # NOTE -- Concatenation because "\e[0m]" does funky stuff.
              output("[\e[0;31m#{fault_type}\e[0m" + "] #{@current_test_text}.")
            else
              output("[  \e[0;32mOK\e[0m  ] #{@current_test_text}.")
            end
            @already_outputted = false
          end

        end
      end
    end
  end
end

