require "rubygems"
require "bundler/setup"

require "#{File.dirname(__FILE__)}/../lib/heroku/kensa"
require 'test/libs'
require 'timecop'
require 'rr'

Response = Struct.new(:code, :body, :cookies) do
  def json_body
    Yajl::Parser.parse(self.body)
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def setup
    Timecop.freeze Time.now.utc
    Artifice.activate_with(ProviderServer.new(manifest))
  end

  def teardown
    Timecop.return
    Artifice.deactivate
  end

  def manifest
    return @manifest if @manifest
    @manifest ||= $manifest || Heroku::Kensa::Manifest.new.skeleton
  end

  def base_url
    manifest["api"]["test"].chomp("/")
  end
end
