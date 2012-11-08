module Action
  module Kensa
    class Git
      class << self
        def verify_create(app_name, template)
          raise CommandInvalid.new("Need git to clone repository") unless git_installed?
        end

        def git_installed?
          `git` rescue false
        end

        def clone(app_name, template)
          verify_create(app_name, template)
          run("git clone #{clone_url(template)} #{app_name}")
        end

        def run(cmd)
          puts cmd
          system(cmd)
        end

        def heroku_prefix
          ENV["REPO_PREFIX"] || "heroku/kensa-create-"
        end

        def clone_url(name)
          if name.include? "://" #its a full url not on github
            return name
          elsif !name.include? "/" #its one of ours 
            name = heroku_prefix + name
          end

          "git://github.com/#{name}"
        end
      end
    end
  end
end
