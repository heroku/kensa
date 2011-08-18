require 'test/helper'
require 'cgi'

class SsoTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    @data = Manifest.new.skeleton.merge(:id => 1)
    @data['api']['test'] = 'http://localhost:4567/'
    @data['api']['sso_salt'] = 'SSO_SALT'
  end

  teardown { Timecop.return }

  def builds_full_url(env)
    url, query = @sso.full_url.split('?')
    data = CGI.parse(query)


    assert_equal "#{@data['api'][env]}heroku/resources/1", url 
    assert_equal 'b6010f6fbb850887a396c2bc0ab23974003008f6', data['token'].first
    assert_equal '1262304000', data['timestamp'].first
  end

  context 'sso' do
    setup { @sso = Sso.new @data }

    test 'builds path' do
      assert_equal '/heroku/resources/1', @sso.path
    end

    test 'builds full url' do
      Timecop.freeze Time.utc(2010, 1)
      builds_full_url('test')
    end

    context 'with no "sso" field specified' do
      test "defaults to GET" do
        assert_equal @sso.full_url, @sso.sso_url
      end
    end

    context 'when sso method is GET' do
      setup do
        @data['api']['sso'] = 'GET'
        @sso = Sso.new @data
      end

      test "#sso_url should be the #full_url" do
        assert_equal @sso.full_url, @sso.sso_url
      end

      test "#message is Opening <full_url>" do
        assert_equal "Opening #{@sso.full_url}", @sso.message
      end
    end

    context 'with sso method is POST' do
      setup do
        Timecop.freeze Time.utc(2010, 1)
        @data['api']['sso'] = 'post'
      end

      test "it starts the proxy server" do
        @sso = Sso.new @data
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
          @sso = Sso.new @data
        end

        test "#sso_url should point to the proxy" do
          assert_equal "http://localhost:#{@sso.proxy_port}/", @sso.sso_url
        end

        test "#post_url contains url and path" do
          assert_equal "http://localhost:4567/heroku/resources/1", @sso.post_url
        end

        test "#message is Posting <data> to <post_url> via proxy on port <proxy_port>" do
          assert_equal "POSTing #{@sso.query_data} to http://localhost:4567/heroku/resources/1 via proxy on port #{@sso.proxy_port}", @sso.message
        end
      end
    end
  end

  context 'sso without salt' do
    setup do
      @data['api'].delete 'sso_salt'
      @sso = Sso.new @data
    end

    test 'builds full url' do
      expected = 'http://localhost:4567/heroku/resources/1'

      assert @sso.full_url.include?(expected)
    end
  end

  context 'sso in a specific environment' do
    setup do
      env = 'production'
      @data[:env] = env
      @data['api'][env] = 'http://localhost:7654/'

      @sso = Sso.new @data
    end

    test 'builds full url' do
      Timecop.freeze Time.utc(2010, 1)
      builds_full_url('production')
    end
  end
end
