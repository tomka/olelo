require 'wiki/app'
require 'sinatra/test/spec'

Rack::MockRequest::DEFAULT_ENV['REMOTE_ADDR'] = 'localhorst'

describe 'wiki' do
  before(:each) do
    @test_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))

    default_config = {
      :title        => 'Git-Wiki',
      :store        => File.join(@test_path, 'store.yml'),
      :cache        => File.join(@test_path, 'cache'),
      :default_mime => 'text/x-creole',
      :main_page    => 'Home',
      :disabled_plugins => ['misc/private_wiki'],
      :rack => {
        :rewrite_base => nil,
        :profiling    => false,
      },
      :git => {
        :repository => File.join(@test_path, 'repository'),
        :workspace  => File.join(@test_path, 'workspace'),
      },
      :log => {
        :level => 'INFO',
        :file  => File.join(@test_path, 'log'),
      },
    }
    Wiki::Config.update default_config

    @app = Wiki::App.new
  end

  after(:each) do
    FileUtils.rm_rf(@test_path)
    @app = nil
  end

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

    get '/not-existing/edit'
    should.be.not_found
  end

  it 'should create page' do
    data = {
      'action' => 'new',
      'content' => 'Content of the Testpage',
      'message' => 'Commit message'
    }
    post('/Testfolder/Testpage', data)

    should.be.redirect
    location.should.equal '/Testfolder/Testpage'

    get '/Testfolder/Testpage'
    should.be.ok

    get '/Testfolder/Testpage/history'
    should.be.ok

    get '/Testfolder/Testpage/edit'
    should.be.ok

    get '/Testfolder/Testpage/append'
    should.be.ok

    get '/Testfolder/Testpage/upload'
    should.be.ok
  end
end
