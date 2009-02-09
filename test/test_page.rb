require 'git_support'

class TC_Object < Test::Unit::TestCase
  include GitSupport

  def test_extension
    assert_equal 'path/name.ext', Wiki::Page.new(@repo, '/path/name.ext').path
  end
end
