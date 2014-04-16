require 'test/helper'

class ManifestTest < Test::Unit::TestCase
  include Heroku::Kensa

  context 'GET manifest' do
    setup { @manifest = Manifest.new(:method => :get) }

    test 'have sso salt' do
      assert_not_nil @manifest.skeleton['api']['sso_salt']
    end

    test 'generates a new sso salt every time' do
      assert @manifest.skeleton['api']['sso_salt'] != Manifest.new.skeleton['api']['sso_salt']
    end

    test 'has an api password' do
      assert_not_nil @manifest.skeleton['api']['password']
    end

    test 'generates a new password every time' do
      assert @manifest.skeleton['api']['password'] != Manifest.new.skeleton['api']['password']
    end

    test 'uses get format' do
      assert_equal @manifest.skeleton['api']['test'], 'http://localhost:4567/'
      assert_equal @manifest.skeleton['api']['production'], 'https://yourapp.com/'
    end

    test 'specifies the US region by default' do
      assert_equal @manifest.skeleton['api']['regions'], ['us']
    end
  end

  context "POST manifest" do
    setup { @manifest = Manifest.new(:method => :post) }

    test 'uses post format for test url' do
      assert_equal @manifest.skeleton['api']['test']['base_url'], 'http://localhost:4567/heroku/resources'
      assert_equal @manifest.skeleton['api']['test']['sso_url'],  'http://localhost:4567/sso/login'
    end

    test 'uses post format for production url' do
      assert_equal @manifest.skeleton['api']['production']['base_url'], 'https://yourapp.com/heroku/resources'
      assert_equal @manifest.skeleton['api']['production']['sso_url'], 'https://yourapp.com/sso/login'
    end

    test 'specifies the US region by default' do
      assert_equal @manifest.skeleton['api']['regions'], ['us']
    end
  end

  context 'manifest without sso' do
    setup do
      options = { :sso => false, :filename => 'test.txt' }
      @manifest = Manifest.new options
    end

    test 'exclude sso salt' do
      assert_nil @manifest.skeleton['api']['sso_salt']
    end
  end
end
