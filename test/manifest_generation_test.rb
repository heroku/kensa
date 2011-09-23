require 'test/helper'
class ManifestGenerationTest < Test::Unit::TestCase
  include Heroku::Kensa

  context 'manifest generation' do
    setup { @manifest = Manifest.new }

    test 'generates a new sso salt every time' do
      assert @manifest.skeleton['api']['sso_salt'] != Manifest.new.skeleton['api']['sso_salt']
    end

    test 'generates a new password every time' do
      assert @manifest.skeleton['api']['password'] != Manifest.new.skeleton['api']['password']
    end
  end

  context 'manifest generation without sso' do
    setup do
      options = { :sso => false }
      @manifest = Manifest.new 'test.txt', options
    end

    test 'exclude sso salt' do
      assert_nil @manifest.skeleton['api']['sso_salt']
    end
  end
end
