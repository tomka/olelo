require 'test/unit'
require 'wiki/config'

class TC_Config < Test::Unit::TestCase
  def test_set
    config = Wiki::Config.new
    config.answer = 42
    assert_equal 42, config.answer

    config.answer = 10
    assert_equal 10, config.answer
  end
end
