require 'wiki/templates'

class Bacon::Context
  include Wiki::Templates
end

describe 'Wiki::Templates' do
  before do
    Wiki::Templates.enable_caching
    Wiki::Templates.paths << File.dirname(__FILE__)
  end

  after do
    Wiki::Templates.paths.clear
    Wiki::Templates.cache.clear
  end

  it 'should have #render' do
    render(:test, :layout => false, :locals => {:text => 'Hello, World!'}).should.equal "<h1>Hello, World!</h1>\n"
    Wiki::Templates.cache.size.should.equal 1
    render(:test, :locals => {:text => 'Blub'}).should.equal "<div id=\"layout\"><h1>Blub</h1>\n</div>\n"
    Wiki::Templates.cache.size.should.equal 2
  end
end
