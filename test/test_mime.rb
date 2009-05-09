require 'wiki/mime'

class TC_Mime < Test::Unit::TestCase
  def test_text?
    assert Wiki::Mime.new('text/plain').text?
    assert Wiki::Mime.new('text/html').text?
    assert !Wiki::Mime.new('application/octet-stream').text?
    assert !Wiki::Mime.new('image/png').text?
  end

  def test_child_of?
    assert Wiki::Mime.new('text/html').child_of?('text/plain')
    assert Wiki::Mime.new('text/x-java').child_of?('text/plain')
  end

  def test_extensions
    assert_equal %w(htm html), Wiki::Mime.new('text/html').extensions
  end

  def test_by_extension
    assert_equal 'text/html', Wiki::Mime.by_extension('html').to_s
    assert_equal 'application/x-ruby', Wiki::Mime.by_extension('rb').to_s
    assert_nil Wiki::Mime.by_extension('crazy')
    assert_nil Wiki::Mime.by_extension('')
  end

  def test_by_magic
    assert_equal 'application/x-executable', Wiki::Mime.by_magic(File.open('/bin/ls')).to_s
    assert_equal 'application/x-sharedlib', Wiki::Mime.by_magic(File.open('/lib/libc.so.6')).to_s
  end
end
