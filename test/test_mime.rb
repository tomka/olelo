require 'test/unit'
require 'wiki'

class TC_Mime < Test::Unit::TestCase
  def test_text?
    assert Mime.by_type('text/plain').text?
    assert Mime.by_type('text/html').text?
    assert !Mime.by_type('application/octet-stream').text?
    assert !Mime.by_type('image/png').text?
  end

  def test_child_of?
    assert Mime.by_type('text/html').child_of?('text/plain')
    assert Mime.by_type('text/x-java').child_of?('text/plain')
  end

  def test_extensions
    assert_equal %w(html htm), Mime.by_type('text/html').extensions
  end

  def test_by_extension
    assert_equal 'text/html', Mime.by_extension('html').to_s
    assert_equal 'application/x-ruby', Mime.by_extension('rb').to_s
  end
end
