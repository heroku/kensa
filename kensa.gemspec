$:.push File.expand_path("../lib", __FILE__)
require "heroku/kensa/version"

Gem::Specification.new do |s|
  s.name = "kensa"
  s.summary = "Tool to help Heroku add-on providers integrating their services"
  s.description = "Kensa is a command-line tool to help add-on providers integrating their services with Heroku. It manages manifest files, and provides a TDD-like approach for programmers to test and develop their APIs."
  s.email = "glenn@heroku.com"
  s.homepage = "http://provider.heroku.com/resources"
  s.authors = ["Blake Mizerany", "Pedro Belo", "Adam Wiggins", "Chris Continanza", "Glenn Gillen"]
  s.version   = Heroku::Kensa::VERSION

  s.rubyforge_project = "kensa"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency(%q<json>, [">= 0"])
  s.add_development_dependency(%q<sinatra>, ["~> 1.2.6"])
  s.add_development_dependency(%q<timecop>, ["~> 0.3.5"])
  s.add_development_dependency(%q<rr>, ["~> 1.0.4"])
  s.add_development_dependency(%q<artifice>, ["~> 0.6"])
  s.add_development_dependency(%q<haml>, ["~> 3.1.3"])
  s.add_runtime_dependency(%q<test-unit>, ["~> 1.2.3"])
  s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.7"])
  s.add_runtime_dependency(%q<yajl-ruby>, ["~> 0.8.3"])
  s.add_runtime_dependency(%q<term-ansicolor>, ["~> 1.0.6"])
  s.add_runtime_dependency(%q<launchy>, ["~> 2.0.5"])
  s.add_runtime_dependency(%q<mechanize>, ["~> 1.0.0"])
  s.add_runtime_dependency(%q<grit>, ["~> 2.4.1"])
end
