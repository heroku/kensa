require_relative 'helper'

class ManifestTest < Test::Unit::TestCase
  include Heroku::Kensa

  context "POST manifest" do
    setup { @manifest = Manifest.new(:method => :post) }

    test 'uses post format for test url' do
      assert_equal @manifest.skeleton['api']['test']['base_url'], 'http://localhost:4567/heroku/resources'
      assert_equal @manifest.skeleton['api']['test']['sso_url'],  'http://localhost:4566/sso/login'
    end

    test 'uses post format for test url' do
      assert_equal @manifest.skeleton['api']['production']['base_url'], 'https://yourapp.com/heroku/resources'
      assert_equal @manifest.skeleton['api']['production']['sso_url'], 'https://yourapp.com/sso/login'
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
