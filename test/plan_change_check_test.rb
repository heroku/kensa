require 'test/helper'

class PlanChangeCheckTest < Test::Unit::TestCase
  include Heroku::Kensa

  setup do
    #Artifice.activate_with(KensaServer.new)
    @data = Manifest.new.skeleton.merge :id => 123, :plan => 'premium'
    @data['api']['password'] = 'secret'
  end

  teardown do
    Artifice.deactivate
  end

  def check ; PlanChangeCheck ; end

  test "working plan change call" do
    @data['api']['test'] += "working"
    assert_valid
  end

  test "detects invalid status" do
    @data['api']['test'] += "invalid-status"
    assert_invalid
  end

  test "detects missing auth" do
    @data['api']['test'] += "invalid-missing-auth"
    assert_invalid
  end
end
