require "rubygems"
require "bundler/setup"

require "#{File.dirname(__FILE__)}/../lib/heroku/kensa"
require 'test/libs'
require 'timecop'
require 'rr'

class Response < Struct.new(:code, :body, :cookies)
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

  # in your test, do
  # @screen = STDOUTScreen.new
  def assert_valid(data=@data, &blk)
    check = create_check(data, &blk)
    check.screen = @screen if @screen
    assert check.call
  end

  def assert_invalid(data=@data, &blk)
    check = create_check(data, &blk)
    check.screen = @screen if @screen
    assert !check.call
  end

  def create_check(data, &blk)
    check = self.check.new(data)
    blk.call(check) if blk
    check
  end

  module Headerize
    attr_accessor :headers
  end

  def to_json(data, headers={})
    body = Yajl::Encoder.encode(data)
    add_headers(body, headers)
  end

  def add_headers(o, headers={})
    o.extend Headerize
    o.headers = {}
    o.headers["Content-Type"] ||= "application/json"
    o.headers.merge!(headers)
    o
  end

  def kensa_stub(meth, o, returns)
    o.instance_eval { @returns = Array(returns) }
    eval <<-EVAL
    def o.#{meth}(*args)
      @returns.shift or fail("Nothing else to return from stub'ed method")
    end
    EVAL
  end
end
