require 'restclient'
require 'term/ansicolor'
require 'launchy'
require 'optparse'

module Heroku
  module Kensa
    class Client
      attr_accessor :options

      def initialize(args, options = {})
        @args    = args
        @options = OptParser.parse(args).merge(options)
      end

      class CommandInvalid < Exception; end

      def run!
        command = @args.shift || @options[:command]
        raise CommandInvalid unless command && respond_to?(command)
        send(command)
      end

      def init
        manifest = Manifest.new(@options)
        protect_current_manifest!
        manifest.write
        screen.message "Initialized new addon manifest in #{filename}\n" 
        if @options[:foreman]
          screen.message "Initialized new .env file for foreman\n"
        end
      end

      def create
        app_name = @args.shift
        template = @options[:template]
        raise CommandInvalid.new("Need to supply an application name") unless app_name
        raise CommandInvalid.new("Need to supply a template") unless template
        begin
          Git.clone(app_name, template) and screen.message "Created #{app_name} from #{template} template\n"
          Dir.chdir(app_name)
          @options[:foreman] = true
          init
        rescue Exception => e
          raise CommandInvalid.new("error cloning #{Git.clone_url(template)} into #{app_name}") 
        end
      end

      def test
        case check = @args.shift
          when "manifest"
            run_check ManifestCheck
          when "provision"
            run_check ManifestCheck, ProvisionCheck
          when "deprovision"
            id = @args.shift || abort("! no id specified; see usage")
            run_check ManifestCheck, DeprovisionCheck, :id => id
          when "planchange"
            id   = @args.shift || abort("! no id specified; see usage")
            plan = @args.shift || abort("! no plan specified; see usage")
            run_check ManifestCheck, PlanChangeCheck, :id => id, :plan => plan
          when "sso"
            id = @args.shift || abort("! no id specified; see usage")
            run_check ManifestCheck, SsoCheck, :id => id
          when "all"
            run_check AllCheck
          when nil
            run_check AllCheck
          else
            abort "! Unknown test '#{check}'; see usage"
        end
      end

      def run
        abort "! missing command to run; see usage" if @args.empty?
        run_check AllCheck, :args => @args
      end

      def sso
        id = @args.shift || abort("! no id specified; see usage")
        data = decoded_manifest
        sso = Sso.new(data.merge(@options).merge(:id => id)).start
        puts sso.message
        Launchy.open sso.sso_url
      end

      def push
        user, password = ask_for_credentials
        host     = heroku_host
        data     = decoded_manifest
        resource = RestClient::Resource.new(host, user, password)
        resource['provider/addons'].post(resolve_manifest, headers)
        puts "-----> Manifest for \"#{data['id']}\" was pushed successfully"
        puts "       Continue at #{(heroku_host)}/provider/addons/#{data['id']}"
      rescue RestClient::UnprocessableEntity, RestClient::BadRequest => e
        abort("FAILED: #{e.response}")
      rescue RestClient::Unauthorized
        abort("Authentication failure")
      rescue RestClient::Forbidden
        abort("Not authorized to push this manifest. Please make sure you have permissions to push it")
      end

      def pull
        addon = @args.first || abort('usage: kensa pull <add-on name>')
        protect_current_manifest!

        user, password = ask_for_credentials
        host     = heroku_host
        resource = RestClient::Resource.new(host, user, password)
        manifest = resource["provider/addons/#{addon}"].get(headers)
        File.open(filename, 'w') { |f| f.puts manifest }
        puts "-----> Manifest for \"#{addon}\" received successfully"
      end

      def version
        puts "Kensa #{VERSION}"
      end

      private
        def protect_current_manifest!
          if manifest_exists?
            print "Manifest already exists. Replace it? (y/n) "
            abort unless gets.strip.downcase == 'y'
            puts
          end
        end
        
        def filename
          @options[:filename]
        end

        def screen
          @screen ||= @options[:silent] ? NilScreen.new : Screen.new
        end

        def headers
          { :accept => :json, "X-Kensa-Version" => "1", "User-Agent" => "kensa/#{VERSION}" }
        end

        def heroku_host
          ENV['ADDONS_URL'] || 'https://addons.heroku.com'
        end

        def resolve_manifest
          if manifest_exists?
            File.read(filename)
          else
            abort("fatal: #{filename} not found")
          end
        end

        def decoded_manifest
          OkJson.decode(resolve_manifest)
        rescue OkJson::Error => e
          raise CommandInvalid, "#{filename} includes invalid JSON"
        end

        def manifest_exists?
          File.exists?(filename)
        end

        def run_check(*args)
          options = {}
          options = args.pop if args.last.is_a?(Hash)

          args.each do |klass|
            data   = decoded_manifest
            check  = klass.new(data.merge(@options.merge(options)), screen)
            result = check.call
            screen.finish
            exit 1 if !result && !(@options[:test])
          end
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
          $stdout.print "\n", red("    #{msg}")
        end

        def result(status)
          msg = status ? green("[PASS]") : red(bold("[FAIL]"))
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


      class OptParser
        def self.parse(args)
          defaults.merge(self.parse_options(args))
        end

        def self.defaults
          {
            :filename => 'addon-manifest.json',
            :env      => "test",
            :async    => false,
          }
        end

        # OptionParser errors out on unnamed options so we have to pull out all the --flags and --flag=somethings
        KNOWN_ARGS = %w{file async production without-sso help plan version sso foreman template}
        def self.pre_parse(args)
          args.partition do |token| 
            token.match(/^--/) && !token.match(/^--(#{KNOWN_ARGS.join('|')})/)
          end.reverse
        end

        def self.parse_provision(flags, args)
          {}.tap do |options|
            flags.each do |arg|
              key, value = arg.split('=')
              unless value
                peek = args[args.index(key) + 1]
                value = peek && !peek.match(/^--/) ? peek : 'true'
              end
              key = key.sub(/^--/,'')
              options[key] = value 
            end
          end
        end

        def self.parse_command_line(args)
          {}.tap do |options|
            OptionParser.new do |o|
              o.on("-f file", "--filename") { |filename| options[:filename] = filename }
              o.on("--async")           { options[:async] = true }
              o.on("--production")      { options[:env] = "production" }
              o.on("--without-sso")     { options[:sso] = false }
              o.on("-h", "--help")      { command = "help" }
              o.on("-p plan", "--plan") { |plan| options[:plan] = plan }
              o.on("-v", "--version")   { options[:command] = "version" }
              o.on("-s sso", "--sso")   { |method| options[:method] = method }
              o.on("--foreman")         { options[:foreman] = true }
              o.on("-t name", "--template") do |template|
                options[:template] = template
              end
              #note: have to add these to KNOWN_ARGS

              begin
                o.parse!(args)
              rescue OptionParser::InvalidOption => e
                raise CommandInvalid, e.message
              end
            end
          end
        end
        
        def self.parse(args)
          if args[0] == 'test' && args[1] == 'provision'
            safe_args, extra_params = self.pre_parse(args)
            self.defaults.tap do |options| 
              options.merge! self.parse_command_line(safe_args)
              options.merge! :options => self.parse_provision(extra_params, args)
            end
          else
            self.defaults.merge(self.parse_command_line(args))
          end
        end
      end 
    end
  end
end
