$:.unshift(File.expand_path("../..",__FILE__))
require 'test/lib/dependencies'
require 'heroku/kensa/client'
require 'test/helper'

class ClientTest < Test::Unit::TestCase
  def test_deprovision_sends_params
    #kensa2 "test deprovision GADFIFZJAH"
  end
end
