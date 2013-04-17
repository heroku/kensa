require_relative 'helper'
require 'cgi'

class SsoTest < Test::Unit::TestCase
  include Heroku::Kensa

  context "via POST" do
    include FsMock
    setup do
      Timecop.freeze Time.utc(2010, 1)
      @data = Manifest.new(:method => :post).skeleton
      @data['api']['sso_salt'] = 'SSO_SALT'
    end

    test "command line" do
      any_instance_of(Client) { |c| stub(c).puts }
      stub(Launchy).open
      start = Object.new
      stub(start).message
      stub(start).sso_url
      stub(Sso).new.stub!.start.returns(start)

      kensa "init"
      kensa "sso 1234"

      assert_received(Sso) { |sso| sso.new(hash_including(:id => '1234')) }
    end

    test "it starts the proxy server" do
      @sso = Sso.new(@data.merge(:id => 1)).start
      body = RestClient.get(@sso.sso_url)

      assert body.include? @sso.path
      assert body.include? 'b6010f6fbb850887a396c2bc0ab23974003008f6'
      assert body.include? '1262304000'
      assert body.include? @sso.url
      assert body.include? @sso.sample_nav_data
    end

    context "with the proxy working" do
      setup do
        any_instance_of(Sso, :run_proxy => false)
        @sso = Sso.new(@data).start
      end

      test "#sso_url should point to the proxy" do
        assert_equal "http://localhost:#{@sso.proxy_port}/", @sso.sso_url
      end

      test "#post_url contains url and path" do
        assert_equal "http://localhost:4567/sso/login", @sso.post_url
      end

      test "#message is Posting <data> to <post_url> via proxy on port <proxy_port>" do
        assert_equal "POSTing #{@sso.query_data} to http://localhost:4567/sso/login via proxy on port #{@sso.proxy_port}", @sso.message
      end
    end
  end
end
