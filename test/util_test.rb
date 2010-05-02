require 'wiki/extensions'
require 'wiki/util'

describe 'wiki utility methods' do
  it 'blank?' do
    ''.should.be.blank
    {}.should.be.blank
    [].should.be.blank
    nil.should.be.blank
    'foo'.should.not.be.blank
    !{42=>'answer'}.should.not.be.blank
    [42].should.not.be.blank
    42.should.not.be.blank
  end

  it 'begins_with?' do
    '123456789'.begins_with?('12').should.equal true
    '123456789'.begins_with?('23').should.not.equal true
  end

  it 'ends with?' do
    '123456789'.ends_with?('89').should.equal true
    '123456789'.ends_with?('98').should.not.equal true
  end

  it 'cleanpath' do
    '/'.cleanpath.should.equal ''
    '/a/b/c/../'.cleanpath.should.equal 'a/b'
    '/a/./b/../c/../d/./'.cleanpath.should.equal 'a/d'
    '1///2'.cleanpath.should.equal '1/2'
    'root'.cleanpath.should.equal ''
    '///root/1/../2'.cleanpath.should.equal '2'
  end

  it 'urlpath' do
    '/'.urlpath.should.equal '/root'
    '/a/b/c/../'.urlpath.should.equal '/a/b'
    '/a/./b/../c/../d/./'.urlpath.should.equal '/a/d'
    '1///2'.urlpath.should.equal '/1/2'
    'root'.urlpath.should.equal '/root'
    '///root/1/../2'.urlpath.should.equal '/2'
  end

  it 'truncate' do
    'Annabel Lee It was many and many a year ago'.truncate(11).should.equal 'Annabel Lee...'
    'In a kingdom by the sea'.truncate(39).should.equal 'In a kingdom by the sea'
  end

  it 'slash' do
    (''/'').should.equal ''
    ('//a/b///'/'').should.equal 'a/b'
    ('a'/'x'/'..'/'b'/'c'/'.').should.equal 'a/b/c'
  end

  it 'check' do
    Wiki::Util.check do |errors|
      # do nothing
    end
    lambda do
      Wiki::Util.check do |errors|
        errors << 'Error 1'
        errors << 'Error 2'
      end
    end.should.raise Wiki::MultiError
  end
end
