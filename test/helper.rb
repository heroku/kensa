require "rubygems"
require "bundler/setup"

require "#{File.dirname(__FILE__)}/../lib/heroku/kensa"
require 'test/lib/dependencies'
require 'timecop'
require 'rr'

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
end
