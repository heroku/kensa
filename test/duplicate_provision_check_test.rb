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

  context "when the provider supports many_per_app" do
    setup { @data["api"]["requires"] = ["many_per_app"] }

    test "allows duplicate provision attempts" do
      use_provider_endpoint "working_duplicate"
      assert_valid
    end

    test "duplicate provisions return different provider ids" do
      use_provider_endpoint "working_duplicate"
      assert_valid
    end

    test "fails when deuplicate provisions return the same provider id" do
      use_provider_endpoint "working"
      assert_invalid
    end
  end
end

