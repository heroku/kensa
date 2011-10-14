require 'rubygems'
require 'bundler/setup'
require 'timecop'
require 'rr'
require 'test/unit'
require 'lib/heroku/kensa'
require 'test/resources/provider_server'

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
