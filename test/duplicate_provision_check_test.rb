require 'test/helper'

class DuplicateProvisionCheckTest < Test::Unit::TestCase
  include Heroku::Kensa
  include ProviderMock

  def check; DuplicateProvisionCheck; end

  setup do
    @data = Manifest.new(method: :post).skeleton
    @data["api"]["password"] = "secret"
    ProviderServer::ProvisionRecord.reset
  end

  context "when the provider does not support many_per_app" do
    setup { @data["api"]["requires"] = [] }

    test "fails when the provider allows duplicate provisions" do
      use_provider_endpoint "working"
      assert_invalid
    end
  end

  context "when the provider does support many_per_app" do
    setup { @data["api"]["requires"] = ["many_per_app"] }

    test "allows duplicate provision attempts" do
      use_provider_endpoint "working"
      assert_valid
    end
  end
end

