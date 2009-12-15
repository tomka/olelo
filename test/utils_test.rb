require 'wiki/extensions'
require 'wiki/utils'

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

  it 'pluralize' do
    'test'.pluralize(0, 'tests').should == '0 tests'
    'test'.pluralize(1, 'tests').should == '1 test'
    'test'.pluralize(3, 'tests').should == '3 tests'
  end

  it 'begins with?' do
    '123456789'.begins_with?('12').should == true
    '123456789'.begins_with?('23').should.not == true
  end

  it 'ends with?' do
    '123456789'.ends_with?('89').should == true
    '123456789'.ends_with?('98').should.not == true
  end

  it 'cleanpath' do
    '/'.cleanpath.should == ''
    '/a/b/c/../'.cleanpath.should == 'a/b'
    '/a/./b/../c/../d/./'.cleanpath.should == 'a/d'
    '1///2'.cleanpath.should == '1/2'
    'root'.cleanpath.should == ''
    '///root/1/../2'.cleanpath.should == '2'
  end

  it 'urlpath' do
    '/'.urlpath.should == '/root'
    '/a/b/c/../'.urlpath.should == '/a/b'
    '/a/./b/../c/../d/./'.urlpath.should == '/a/d'
    '1///2'.urlpath.should == '/1/2'
    'root'.urlpath.should == '/root'
    '///root/1/../2'.urlpath.should == '/2'
  end

  it 'truncate' do
    'Annabel Lee It was many and many a year ago'.truncate(11).should == 'Annabel Lee...'
    'In a kingdom by the sea'.truncate(39).should == 'In a kingdom by the sea'
  end

  it 'slash' do
    ''/''.should == ''
    '//a/b///'/''.should == 'a/b'
    'a'/'x'/'..'/'b'/'c'/'.'.should == 'a/b/c'
  end

  it 'forbid' do
    assert_raise Wiki::MultiError do
      forbid('Forbidden' => true)
    end
    assert_raise Wiki::MultiError do
      forbid('Allowed'   => false,
             'Forbidden' => true)
    end
  end
end
