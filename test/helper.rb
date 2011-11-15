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

  #Wanted to try something like for integration tests, but all these approaches
  #have problems.

  #- runs tests within a test, easiest to stub server
  def kensa(cmd, options = {})
    client = Heroku::Kensa::Client.new(cmd.split, options)
    stub(client).resolve_manifest { manifest }
    client.run!
  end

  #- runs tests within a test, can't grab stderr 
  def kensa2(cmd)
    $stdout = @stdout = StringIO.new
    ARGV.clear
    cmd.split.each { |token| ARGV << token }
    load './bin/kensa'
  end

  # how to set up an endpoint - can't use artifice, running server is 
  # possible but messy
  def kensa3(cmd)
    Open3.popen3("./bin/kensa #{cmd}") { |stdin, stdout, stderr|
      stdin.close
      @stdout, @stderr = stdout.read, stderr.read
    }
  end

  def teardown
    Timecop.return
    Artifice.deactivate
  end
end
