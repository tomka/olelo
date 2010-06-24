# -*- coding: utf-8 -*-
require 'helper'

Rack::MockRequest::DEFAULT_ENV['REMOTE_ADDR'] = 'localhorst'

class Bacon::Context
  include Rack::Test::Methods
  include Wiki::Util

  attr_reader :app
end

describe 'requests' do
  before do
    @test_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    @app_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

    default_config = {
      :title             => 'Git-Wiki',
      :app_path          => @app_path,
      :plugins_path      => File.join(@app_path, 'plugins'),
      :config_path       => File.join(@app_path, 'config'),
      :initializers_path => File.join(@app_path, 'config', 'initializers'),
      :production        => true,
      :locale	         => 'en_US',
      :root_path         => 'Root',
      :index_page        => 'Index',
      :sidebar_page      => 'Sidebar',
      :external_images   => false,
      :cache             => File.join(@test_path, 'cache'),
      :namespaces => {
        :discussion => 'Discussion:',
        :metadata   => 'Metadata:',
      },
      :authentication => {
        :service  => :yamlfile,
        :yamlfile => {
          :store  => File.join(@test_path, 'users.yml'),
        },
      },
      :mime => [
                'extension',
                'content',
                'text/x-creole',
               ],
      :disabled_plugins => [
                            'authorization/private_wiki',
                            'tagging',
                            'editor/antispam',
                            'filter/benchmark',
                           ],
      :repository => {
        :type  => :git,
        :git => {
          :path => File.join(@test_path, 'repository'),
        },
      }
    }

    Wiki::Config.update(default_config)
    Wiki::Repository.instance = nil

    logger = Logger.new(File.join(@app_path, 'test.log'))

    @app = Rack::Builder.new do
      run Wiki::Application.new(nil, :logger => logger)
    end
  end

  after do
    FileUtils.rm_rf(@test_path)
    @app = nil
  end

  it 'should have empty repository' do
    get '/'
    last_response.should.be.redirect
    last_response.location.should.equal '/new'
  end

  it 'should show login page' do
    get '/login'
    last_response.should.be.ok
    last_response.body.should.include '<form action="/signup" method="post">'
    last_response.body.should.include '<form action="/login" method="post">'
  end

  it 'should show to /new' do
    get '/not-existing/new'
    last_response.should.be.ok
  end

  it 'should redirect to /new' do
    get '/not-existing'
    last_response.should.be.redirect
    last_response.location.should.equal '/not-existing/new'

    get '/not-existing/edit'
    last_response.should.be.redirect
    last_response.location.should.equal '/not-existing/new'
  end

  it 'should not redirect to /new' do
    get '/not-existing/history'
    last_response.should.be.not_found

    get '/not-existing/diff'
    last_response.should.be.not_found
  end

  it 'should create page' do
    data = {
      'action' => 'new',
      'content' => 'Content of the Testpage',
      'comment' => 'My Comment'
    }
    post('/Testfolder/Testpage', data)

    last_response.should.be.redirect
    last_response.location.should.equal '/Testfolder/Testpage'

    get '/'
    last_response.should.be.ok

    get '/Testfolder/Testpage'
    last_response.should.be.ok
    last_response.body.should.include '<h1>Testpage</h1>'
    last_response.body.should.include 'Content of the Testpage'

    get '/Testfolder/Testpage/history'
    last_response.should.be.ok
    last_response.body.should.include 'My Comment'

    get '/Testfolder/Testpage/edit'
    last_response.should.be.ok

    get '/Testfolder/Testpage/upload'
    last_response.should.be.ok
  end

  it 'should create page with special characters' do
    data = {
      'action' => 'new',
      'content' => 'すみませんわかりません',
      'comment' => '测试'
    }
    post(escape('/子供を公園/中文'), data)
    last_response.should.be.redirect

    unescape(last_response.location).should.equal '/子供を公園/中文'

    get escape('/子供を公園/中文')
    last_response.should.be.ok

    get escape('/子供を公園/中文/history')
    last_response.should.be.ok

    get escape('/子供を公園/中文/edit')
    last_response.should.be.ok

    get escape('/子供を公園/中文/upload')
    last_response.should.be.ok
  end
end
