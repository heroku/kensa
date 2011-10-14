$:.unshift(File.expand_path("../..",__FILE__))
require 'test/helper'
class ManifestGenerationTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    super
    @manifest = Manifest.new
  end

  def test_generates_a_new_sso_salt_every_time
    assert @manifest.skeleton['api']['sso_salt'] != Manifest.new.skeleton['api']['sso_salt']
  end

  def test_generates_a_new_password_every_time
    assert @manifest.skeleton['api']['password'] != Manifest.new.skeleton['api']['password']
  end
end

class ManifestGenerationWithoutSSOTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    super
    options = { :sso => false }
    @manifest = Manifest.new 'test.txt', options
  end

  def test_exclude_sso_salt
    assert_nil @manifest.skeleton['api']['sso_salt']
  end
end
