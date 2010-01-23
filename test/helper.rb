require 'contest'

class Test::Unit::TestCase

  def assert_error(msg)
    errors = Array(@data.errors)
    assert_block "'#{msg}' is not contained in #{errors.inspect}" do
      errors.include?(msg)
    end
  end

end
