require 'wiki/extensions'
require 'wiki/util'

describe 'Wiki::Util' do
  it 'should have #check' do
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

  it 'should have #escape which escapes space as %20' do
    Wiki::Util.escape('+@ ').should.equal '%2B%40%20'
  end

  it 'should have #unescape which does not unescape +' do
    Wiki::Util.unescape('+%20+').should.equal '+ +'
  end

  it 'should have #escape_html' do
    Wiki::Util.escape_html('<').should.equal '&lt;'
  end

  it 'should have #unescape_html' do
    Wiki::Util.unescape_html('&lt;').should.equal '<'
  end

  it 'should have #escape_json' do
    Wiki::Util.escape_json('a&b<c>').should.equal 'a\u0026b\u003Cc\u003E'
  end

  it 'should have xml #builder' do
    Wiki::Util.builder do
      entry {
        attribute(:key => 'a') {
          text 'text'
        }
      }
    end.should.equal '<entry><attribute key="a">text</attribute></entry>'
  end

  it 'should have #md5' do
    Wiki::Util.md5('test').should.equal '098f6bcd4621d373cade4e832627b4f6'
  end

  it 'should have #sha256' do
    Wiki::Util.sha256('test').should.equal '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'
  end

  it 'should have #build_query' do
    Wiki::Util.build_query(:a => 1, :b => [1, 2, 3]).should.equal 'a=1&b=1&b=2&b=3'
  end

  it 'should have #shell_filter' do
    Wiki::Util.shell_filter("sed 's/x/y/g'", 'axa').should.equal 'aya'
    Wiki::Util.shell_filter('tr a b', 'a' * 6666666).should.equal 'b' * 6666666
  end
end
