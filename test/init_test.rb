require 'test/helper'
require 'fakefs'

class InitTest < Test::Unit::TestCase
  def setup
    @filename = 'addon-manifest.json'
  end

  def teardown
    File.unlink(@filename) if @filename && File.exist?(@filename)
  end
  
  def test_init_default_so_sso_post
    kensa "init"
    manifest = read_json(@filename)
    %w{test production}.each do |env|
      %w{base_url sso_url}.each do |url|
        assert manifest['api'][env][url] =~ /^http/
      end
    end
  end

  def test_init_uses_file_flag
    @filename = 'foo.json'

    kensa "init -f #{@filename}"
    assert !File.exist?('./addon-manifest.json')
    manifest = read_json(@filename)
  end

  def test_init_uses_sso_flag
    kensa "init --sso get"
    manifest = read_json(@filename)
    %w{test production}.each do |env|
      assert manifest['api'][env] =~ /^http/
    end
  end
end
