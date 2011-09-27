desc 'Run all unit tests'
task :test do
  system "turn test/*.rb"
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
    gemspec.email = "glenn@heroku.com"
    gemspec.homepage = "http://provider.heroku.com/resources"
    gemspec.authors = ["Blake Mizerany", "Pedro Belo", "Adam Wiggins", "Chris Continanza", "Glenn Gillen"]

    gemspec.add_development_dependency(%q<turn>, ["~> 0.8.2"])
    gemspec.add_development_dependency(%q<contest>, ["~> 0.1.3"])
    gemspec.add_development_dependency(%q<timecop>, ["~> 0.3.5"])
    gemspec.add_development_dependency(%q<sinatra>, ["~> 1.2.6"])
    gemspec.add_development_dependency(%q<rr>, ["~> 1.0.4"])
    gemspec.add_development_dependency(%q<artifice>, ["~> 0.6"])
    gemspec.add_development_dependency(%q<haml>, ["~> 3.1.3"])
    gemspec.add_dependency(%q<rest-client>, ["~> 1.6.7"])
    gemspec.add_dependency(%q<yajl-ruby>, ["~> 0.8.3"])
    gemspec.add_dependency(%q<term-ansicolor>, ["~> 1.0.6"])
    gemspec.add_dependency(%q<launchy>, ["~> 2.0.5"])
    gemspec.add_dependency(%q<mechanize>, ["~> 1.0.0"])

    gemspec.version = Heroku::Kensa::VERSION
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
