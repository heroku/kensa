require 'heroku/kensa'
require 'heroku/kensa/client'
require 'contest'
require 'timecop'
require 'rr'
require 'artifice'
require 'test/resources/server'
require 'fakefs/safe'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  module ProviderMock
    def setup
      Artifice.activate_with(ProviderServer)
      super
    end

    def teardown
      Artifice.deactivate
      super
    end
  end

  module FsMock
    def setup
      FakeFS.activate!
      @filename = 'addon-manifest.json'
      super
    end

    def teardown
      File.unlink(@filename) if @filename && File.exist?(@filename)
      FakeFS.deactivate!
      super
    end
  end

  def kensa(command)
    Heroku::Kensa::Client.new(command.split, :silent => true, :test => true).run!
  end

  def read_json(filename)
    OkJson.decode(File.open(filename).read)
  end

  #this prepends a prefix for the provider server
  #in test/resources/server.rb
  def use_provider_endpoint(name, type = 'base')
    if @data['api']['test'].is_a? Hash
      url = @data['api']['test']["#{type}_url"]
      path = URI.parse(url).path
      @data['api']['test']["#{type}_url"] = url.sub(path, "/#{name}#{path}")
    else
      @data['api']['test'] += "#{name}"
    end
  end

  def trace!
    @screen = Heroku::Kensa::IOScreen.new(STDOUT)
  end

  def screen
    @screen ||= Heroku::Kensa::IOScreen.new(StringIO.new("", 'w+'))
  end

  # call trace! in your test before the
  # assert to see the output
  def assert_valid(data=@data, &blk)
    check = create_check(data, &blk)
    result = check.call
    assert result, screen.to_s
  end

  def assert_invalid(data=@data, &blk)
    check = create_check(data, &blk)
    result = check.call
    assert !result, screen.to_s
  end

  def create_check(data, &blk)
    check = self.check.new(data, screen)
    blk.call(check) if blk
    check
  end

  module Headerize
    attr_accessor :headers
  end

  def to_json(data, headers={})
    body = OkJson.encode(data)
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
