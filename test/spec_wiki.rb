require 'wiki/app'
require 'test/spec'
require 'rack/test'

Rack::MockRequest::DEFAULT_ENV['REMOTE_ADDR'] = 'localhorst'

describe 'wiki' do
  include Rack::Test::Methods
  attr_reader :app

  def should
    last_response.should
  end

  def method_missing(name, *args, &block)
    if last_response && last_response.respond_to?(name)
      last_response.send(name, *args, &block)
    else
      super
    end
  end

  before(:each) do
    @test_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))

    default_config = {
      :title        => 'Git-Wiki',
      :root         => File.expand_path(File.join(File.dirname(__FILE__), '..')),
      :store        => File.join(@test_path, 'store.yml'),
      :cache        => File.join(@test_path, 'cache'),
      :locale       => 'en',
      :mime => {
        :default => 'text/x-creole',
        :magic => true,
      },
      :main_page    => 'Home',
      :disabled_plugins => [
        'authorization/private_wiki',
        'tagging',
        'filter/orgmode',
        'tag/math-ritex',
        'tag/math-itex2mml',
        # 'tag/math-imaginator',
      ],
      :disabled_plugins => ['authorization/private_wiki'],
      :production => false,
      :rack => {
        :rewrite_base => nil,
        :profiling    => false,
      },
      :git => {
        :repository => File.join(@test_path, 'repository'),
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
  end

  it 'should not redirect to /new' do
    get '/not-existing/edit'
    should.be.not_found

    get '/not-existing/history'
    should.be.not_found

    get '/not-existing/diff'
    should.be.not_found

    get '/not-existing/archive'
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

    get '/Testfolder/Testpage/upload'
    should.be.ok
  end
end
