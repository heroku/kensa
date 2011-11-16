desc 'Run all unit tests'
task :test do
  fork do
    exec "ruby test/resources/server.rb > /dev/null 2>&1"
    #exec "ruby test/resources/server.rb > log.txt 2>&1"
  end
  system "turn test"
  system "ps -ax | grep test/resources/server.rb | grep -v grep | awk '{print $1}' | xargs kill"
end

task :default => :test

begin
  $: << File.join(File.dirname(__FILE__), 'lib')
  require 'jeweler'
  require 'heroku/kensa'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "kensa"
    gemspec.summary = "Tool to help Heroku add-on providers integrating their services"
    gemspec.description = "Kensa is a command-line tool to help add-on providers integrating their services with Heroku. It manages manifest files, and provides a TDD-like approach for programmers to test and develop their APIs."
    gemspec.email = "pedro@heroku.com"
    gemspec.homepage = "http://provider.heroku.com/resources"
    gemspec.authors = ["Blake Mizerany", "Pedro Belo", "Adam Wiggins", "Chris Continanza"]

    gemspec.add_development_dependency(%q<turn>, [">= 0"])
    gemspec.add_development_dependency(%q<contest>, [">= 0"])
    gemspec.add_development_dependency(%q<timecop>, [">= 0.3.5"])
    gemspec.add_development_dependency(%q<sinatra>, [">= 0.9"])
    gemspec.add_dependency(%q<rest-client>, [">= 1.4.0", "< 1.7.0"])
    gemspec.add_dependency(%q<yajl-ruby>, ["~> 0.6"])
    gemspec.add_dependency(%q<term-ansicolor>, ["~> 1.0"])
    gemspec.add_dependency(%q<launchy>, [">= 0.3.2"])
    gemspec.add_dependency(%q<mechanize>, ["~> 1.0.0"])

    gemspec.version = Heroku::Kensa::VERSION
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
