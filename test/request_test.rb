# -*- coding: utf-8 -*-
require 'helper'
require 'rack/force_encoding'

Rack::MockRequest::DEFAULT_ENV['REMOTE_ADDR'] = 'localhorst'

class Bacon::Context
  include Rack::Test::Methods
  include Olelo::Util

  attr_reader :app
end

describe 'requests' do
  before do
    @test_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    @app_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

    default_config = {
      :title             => 'Ōlelo',
      :app_path          => @app_path,
      :plugins_path      => File.join(@app_path, 'plugins'),
      :config_path       => File.join(@app_path, 'config'),
      :initializers_path => File.join(@app_path, 'config', 'initializers'),
      :views_path        => File.join(@app_path, 'views'),
      :themes_path       => File.join(@app_path, 'static', 'themes'),
      :tmp_path          => File.join(@test_path, 'tmp'),
      :base_path         => '/',
      :production        => true,
      :locale	         => 'en_US',
      :sidebar_page      => 'Sidebar',
      :external_images   => false,
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
                            'security/readonly_wiki',
			    'security/private_wiki',
                            'editor/antispam',
                            'filter/benchmark',
                           ],
      :repository => {
        :type  => 'git',
        :git => {
          :path => File.join(@test_path, 'repository'),
          :bare => true,
        },
      }
    }

    Olelo::Config.update(default_config)
    Olelo::Repository.instance = nil

    FileUtils.mkpath Olelo::Config.tmp_path, :mode => 0755
    logger = Logger.new(File.join(@app_path, 'test.log'))

    @app = Rack::Builder.new do
      if ''.respond_to? :encoding
        require 'rack/force_encoding'
        use Rack::ForceEncoding
      end
      run Olelo::Application.new(nil, :logger => logger)
    end

  end

  after do
    FileUtils.rm_rf(@test_path)
    @app = nil
    Olelo::Filter.registry.clear
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
  end

  it 'should not redirect to /new' do
    get '/not-existing/edit'
    last_response.should.be.not_found

    get '/not-existing/history'
    last_response.should.be.not_found
  end

  it 'should create page' do
    data = {
      'action' => 'edit',
      'content' => 'Content of the Testpage',
      'comment' => 'My Comment',
      'close' => '1'
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
  end

  it 'should create page with special characters' do
    data = {
      'action' => 'edit',
      'content' => 'すみませんわかりません',
      'comment' => '测试',
      'close' => '1'
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
  end
end
