require 'wiki'
require 'sinatra/test/rspec'

describe 'Wiki' do

  before do
    `rm -rf data/test`
    config_file = File.expand_path(File.join(File.dirname(__FILE__), 'config-test.yml'))
    Wiki::App.set :config, YAML.load_file(config_file)
    @app = Wiki::App
  end

  it 'should redirect /' do
    get '/'
    @response.should be_redirect
    @response.location.should == '/home.text'
  end
end
