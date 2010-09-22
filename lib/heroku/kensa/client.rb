require 'restclient'
require 'term/ansicolor'
require 'launchy'

module Heroku
  module Kensa
    class Client

      def initialize(args, options)
        @args    = args
        @options = options
      end

      def filename
        @options[:filename]
      end

      class CommandInvalid < Exception; end

      def run!
        command = @args.shift || @options[:command]
        raise CommandInvalid unless command && respond_to?(command)
        send(command)
      end

      def init
        Manifest.new(filename, @options).write
        Screen.new.message "Initialized new addon manifest in #{filename}"
      end

      def test
        case check = @args.shift
          when "manifest"
            run_check ManifestCheck
          when "provision"
            run_check ManifestCheck
            run_check ProvisionCheck
          when "deprovision"
            id = ARGV.shift || abort("! no id specified; see usage")
            run_check ManifestCheck
            run_check DeprovisionCheck, :id => id
          when "planchange"
            id   = ARGV.shift || abort("! no id specified; see usage")
            plan = ARGV.shift || abort("! no plan specified; see usage")
            run_check ManifestCheck
            run_check PlanChangeCheck, :id => id, :plan => plan
          when "sso"
            id = ARGV.shift || abort("! no id specified; see usage")
            run_check ManifestCheck
            run_check SsoCheck, :id => id
          else
            abort "! Unknown test '#{check}'; see usage"
        end
      end

      def run
        abort "! missing command to run; see usage" if ARGV.empty?
        run_check ManifestCheck
        run_check AllCheck, :args => ARGV
      end

      def sso
        id = ARGV.shift || abort("! no id specified; see usage")
        data = Yajl::Parser.parse(resolve_manifest).merge(:id => id)
        sso = Sso.new(data.merge(@options))
        puts "Opening #{sso.full_url}"
        Launchy.open sso.full_url
      end

      def push
        user, password = ask_for_credentials
        host     = ENV['ADDONS_HOST'] || 'https://addons.heroku.com'
        data     = Yajl::Parser.parse(resolve_manifest)
        resource = RestClient::Resource.new(host, user, password)
        resource['provider/addons'].post(resolve_manifest)
        puts "-----> Manifest for \"#{data['id']}\" was pushed successfully"
        puts "       Continue at https://provider.heroku.com/addons/#{data['id']}"
      rescue RestClient::Unauthorized
        abort("Authentication failure")
      rescue RestClient::Forbidden
        abort("Not authorized to push this manifest. Please make sure you have permissions to push it")
      end

      def version
        puts "Kensa #{VERSION}"
      end

      private

        def resolve_manifest
          if File.exists?(filename)
            File.read(filename)
          else
            abort("fatal: #{filename} not found")
          end
        end

        def run_check(klass, args={})
          screen = Screen.new
          data = Yajl::Parser.parse(resolve_manifest)
          check = klass.new(data.merge(@options.merge(args)), screen)
          check.call
          screen.finish
        end

        def running_on_windows?
          RUBY_PLATFORM =~ /mswin32|mingw32/
        end

        def echo_off
          system "stty -echo"
        end

        def echo_on
          system "stty echo"
        end

        def ask_for_credentials
          puts "Enter your Heroku Provider credentials."

          print "Email: "
          user = gets.strip

          print "Password: "
          password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

          [ user, password ]
        end

        def ask_for_password_on_windows
          require "Win32API"
          char = nil
          password = ''

          while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
            break if char == 10 || char == 13 # received carriage return or newline
            if char == 127 || char == 8 # backspace and delete
              password.slice!(-1, 1)
            else
              password << char.chr
            end
          end
          puts
          return password
        end

        def ask_for_password
          echo_off
          password = gets.strip
          puts
          echo_on
          return password
        end


      class Screen
        include Term::ANSIColor

        def test(msg)
          $stdout.puts
          $stdout.puts
          $stdout.print "Testing #{msg}"
        end

        def check(msg)
          $stdout.puts
          $stdout.print "  Check #{msg}"
        end

        def error(msg)
          $stdout.print "\n", magenta("    ! #{msg}")
        end

        def result(status)
          msg = status ? bold("[PASS]") : red(bold("[FAIL]"))
          $stdout.print " #{msg}"
        end

        def message(msg)
          $stdout.print msg
        end

        def finish
          $stdout.puts
          $stdout.puts
          $stdout.puts "done."
        end
      end
    end
  end
end
