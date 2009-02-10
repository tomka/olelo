require 'test/unit'
require 'wiki'

class TC_Mime < Test::Unit::TestCase
  def test_text?
    assert Mime.new('text/plain').text?
    assert Mime.new('text/html').text?
    assert !Mime.new('application/octet-stream').text?
    assert !Mime.new('image/png').text?
  end

  def test_child_of?
    assert Mime.new('text/html').child_of?('text/plain')
    assert Mime.new('text/x-java').child_of?('text/plain')
  end

  def test_extensions
    assert_equal %w(htm html), Mime.new('text/html').extensions
  end

  def test_by_extension
    assert_equal 'text/html', Mime.by_extension('html').to_s
    assert_equal 'application/x-ruby', Mime.by_extension('rb').to_s
    assert_nil Mime.by_extension('crazy')
    assert_nil Mime.by_extension('')
  end
end
