require 'test/helper'

class ManifestTest < Test::Unit::TestCase
  include Heroku::Kensa

  context 'manifest' do
    setup { @manifest = Manifest.new }

    test 'have sso salt' do
      assert_not_nil @manifest.skeleton['api']['sso_salt']
    end
  end

  context 'manifest without sso' do
    setup do
      options = { :sso => false }
      @manifest = Manifest.new 'test.txt', options
    end

    test 'exclude sso salt' do
      assert_nil @manifest.skeleton['api']['sso_salt']
    end
  end
end
