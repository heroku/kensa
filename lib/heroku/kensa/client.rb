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
        command = @args.shift
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
        require_heroku
        client   = Heroku::Command.run "auth:client", ['--ignore-keys']
        host     = ENV['ADDONS_HOST'] || 'https://addons.heroku.com'
        resource = RestClient::Resource.new(host, client.user, client.password)
        resource['provider/addons'].post(resolve_manifest)
        puts "Manifest pushed succesfully"
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

        def require_heroku
          require 'heroku'
          require 'heroku/command'
          require 'heroku/commands/auth'
        rescue LoadError
          abort("fatal: Could not load the Heroku gem. Plase make sure the Heroku gem is available and up to date")
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
          $stdout.puts msg
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
