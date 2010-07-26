require 'wiki/templates'

class Bacon::Context
  include Wiki::Templates
end

describe 'Wiki::Templates' do
  before do
    Wiki::Templates.enable_caching
    Wiki::Templates.loader << Wiki::Templates::InlineLoader.new(__FILE__)
  end

  after do
    Wiki::Templates.loader.clear
    Wiki::Templates.cache.clear
  end

  it 'should have #render' do
    render(:test, :locals => {:text => 'Hello, World!'}).should.equal "<h1>Hello, World!</h1>\n"
    Wiki::Templates.cache.size.should.equal 1
  end

  it 'should support haml options' do
    render(:test, :locals => {:text => '< bad characters >'}).should.equal "<h1>< bad characters ></h1>\n"
    render(:test, :escape_html => true, :locals => {:text => '< bad characters >'}).should.equal "<h1>&lt; bad characters &gt;</h1>\n"
  end
end

__END__

@@ test.haml
%h1= text

