# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "heroku/kensa/version"

Gem::Specification.new do |s|
  s.name = %q{kensa}
  s.version = Heroku::Kensa::VERSION
  s.platform = Gem::Platform::RUBY

  s.license = 'MIT'

  s.authors = ["Blake Mizerany", "Pedro Belo", "Adam Wiggins", 'Glenn Gillen', 'Chris Continanza', 'Matthew Conway']
  s.default_executable = %q{kensa}
  s.description = %q{Kensa is a command-line tool to help add-on providers integrating their services with Heroku. It manages manifest files, and provides a TDD-like approach for programmers to test and develop their APIs.}
  s.email = %q{provider@heroku.com}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.homepage = %q{http://provider.heroku.com/resources}
  s.required_ruby_version = '>= 1.9.0'
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Tool to help Heroku add-on providers integrating their services}

  s.add_runtime_dependency(%q<launchy>, "~> 2.2.0")
  s.add_runtime_dependency(%q<mechanize>, "~> 2.7.5")
  s.add_runtime_dependency(%q<netrc>, "~> 0.10.3")
  s.add_runtime_dependency(%q<rest-client>, "~> 2.0")
  s.add_runtime_dependency(%q<colored>, "~> 1.2")

  s.add_development_dependency(%q<artifice>, "~> 0.6")
  s.add_development_dependency(%q<contest>, "~> 0.1.3")
  s.add_development_dependency(%q<fakefs>, "~> 0.4.2")
  s.add_development_dependency(%q<rake>)
  s.add_development_dependency(%q<rr>, "~> 1.0.4")
  s.add_development_dependency(%q<sinatra>, "~> 1.4.7")
  s.add_development_dependency(%q<timecop>, "~> 0.6.1")
  s.add_development_dependency(%q<pry>)
  s.add_development_dependency(%q<test-unit>)
end

