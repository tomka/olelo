# -*- coding: utf-8 -*-
require 'spec_setup'

Rack::MockRequest::DEFAULT_ENV['REMOTE_ADDR'] = 'localhorst'

class Bacon::Context
  include Rack::Test::Methods
  include Wiki::Util

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
end

describe 'wiki' do
  before do
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
        'filter/orgmode',
	'editor/antispam'
      ],
      :production => false,
      :rack => {
        :rewrite_base => nil,
        :profiling    => false,
      },
      :git => {
        :repository => File.join(@test_path, 'repository'),
      },
      :log => {
        :level => 'DEBUG',
        :file  => File.expand_path(File.join(@test_path, '..', '..', 'test.log')),
      },
    }
    Wiki::Config.update default_config

    @app = Rack::Builder.new do
      logger = ::Logger.new(Wiki::Config.log.file)
      logger.level = ::Logger.const_get(Wiki::Config.log.level)
      run Wiki::Application.new(nil, :logger => logger)
    end
  end

  after do
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
    should.be.redirect
    location.should.equal '/not-existing/new'
  end

  it 'should not redirect to /new' do
    get '/not-existing/history'
    should.be.not_found

    get '/not-existing/diff'
    should.be.not_found
  end

  it 'should create page' do
    data = {
      'action' => 'new',
      'content' => 'Content of the Testpage',
      'comment' => 'Comment'
    }
    post('/Testfolder/Testpage', data)

    should.be.redirect
    location.should.equal '/Testfolder/Testpage'

    get '/Testfolder/Testpage'
    should.be.ok
    body.should.include '<h1>Testpage</h1>'
    body.should.include 'Content of the Testpage'

    get '/Testfolder/Testpage/history'
    should.be.ok
    body.should.include 'Comment'

    get '/Testfolder/Testpage/edit'
    should.be.ok

    get '/Testfolder/Testpage/upload'
    should.be.ok
  end

  it 'should create page with special characters' do
    data = {
      'action' => 'new',
      'content' => 'すみませんわかりません',
      'comment' => '测试'
    }
    post(escape('/子供を公園/中文'), data)
    should.be.redirect

    unescape(location).should.equal '/子供を公園/中文'

    get escape('/子供を公園/中文')
    should.be.ok

    get escape('/子供を公園/中文/history')
    should.be.ok

    get escape('/子供を公園/中文/edit')
    should.be.ok

    get escape('/子供を公園/中文/upload')
    should.be.ok
  end
end
