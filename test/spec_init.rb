require 'wiki'
require 'sinatra/test/spec'

shared_context 'wiki init' do
  before  do
    @test_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))

    config = {
      'title'        => 'Git-Wiki',
      'repository'   => File.join(@test_path, 'repository'),
      'workspace'    => File.join(@test_path, 'workspace'),
      'store'        => File.join(@test_path, 'store.yml'),
      'cache'        => File.join(@test_path, 'cache'),
      'loglevel'     => 'INFO',
      'logfile'      => File.join(@test_path, 'log'),
      'default_mime' => 'text/x-creole',
    }
    Wiki::App.set :config, config
    @app = Wiki::App
  end

  after do
    FileUtils.rm_rf(@test_path)
  end
end
