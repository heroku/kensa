require_relative 'helper'
require 'cgi'

class SsoTest < MiniTest::Unit::TestCase
  include Heroku::Kensa
  include FsMock
  def setup
    Timecop.freeze Time.utc(2010, 1)
    @data = Manifest.new(:method => :post).skeleton
    @data['api']['sso_salt'] = 'SSO_SALT'
  end

  def test_command_line
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

  def test_it_starts_the_proxy_server
    @sso = Sso.new(@data.merge(:id => 1)).start
    body = RestClient.get(@sso.sso_url)

    assert body.include? @sso.path
    assert body.include? 'b6010f6fbb850887a396c2bc0ab23974003008f6'
    assert body.include? '1262304000'
    assert body.include? @sso.url
    assert body.include? @sso.sample_nav_data
  end

  def setup
    any_instance_of(Sso, :run_proxy => false)
    @sso = Sso.new(@data).start
  end

  def test_sso_url_should_point_to_the_proxy
    assert_equal "http://localhost:#{@sso.proxy_port}/", @sso.sso_url
  end

  def test_post_url_contains_url_and_path
    assert_equal "http://localhost:4567/sso/login", @sso.post_url
  end

  def test_message_is_posting_to_data
    assert_equal "POSTing #{@sso.query_data} to http://localhost:4567/sso/login via proxy on port #{@sso.proxy_port}", @sso.message
  end
end
