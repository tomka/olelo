require 'spec_init'

describe 'wiki' do
  behaves_like 'wiki init'

  it 'should redirect /' do
    get '/'
    should.be.redirect
    location.should.equal '/Home'
  end

  it 'should show login page' do
    get '/login'
    should.be.ok
    body.should.include '<form action="/signup" method="post">'
    body.should.include '<form action="/login" method="post">'
  end

  it 'should show to /new' do
    get '/not-existing/new'
    should.be.ok
  end

  it 'should redirect to /new' do
    get '/not-existing'
    should.be.redirect
    location.should.equal '/not-existing/new'
  end

end
