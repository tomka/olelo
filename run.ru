#!/usr/bin/env rackup

ENV['RACK_ENV'] = env

path = File.expand_path(File.dirname(__FILE__))

$: << File.join(path, 'lib') << File.join(path, 'deps/sinatra/lib')
require 'wiki/app'
require 'rack/path_info'
require 'rack/esi'

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  File.join(path, 'config.yml')
end

# FIXME: Problem with fastcgi handler
if server == 'fastcgi'
  options.delete :File
  options.delete :Port
end

default_config = {
  :title        => 'Git-Wiki',
  :store        => File.join(path, '.wiki', 'store.yml'),
  :cache        => File.join(path, '.wiki', 'cache'),
  :default_mime => 'text/x-creole',
  :main_page    => 'Home',
  :disabled_plugins => ['misc/private_wiki'],
  :rack => {
    :rewrite_base => nil,
    :profiling    => false,
    :tidy         => nil
  },
  :git => {
    :repository => File.join(path, '.wiki', 'repository'),
    :workspace  => File.join(path, '.wiki', 'workspace'),
  },
  :log => {
    :level => 'INFO',
    :file  => File.join(path, '.wiki', 'log'),
  },
}

Wiki::Config.update(default_config)
Wiki::Config.load(config_file)

if Wiki::Config.rack.profiling
  require 'rack/contrib'
  use Rack::Profiler, :printer => :graph
end

use Rack::Session::Pool
use Rack::PathInfo

if !Wiki::Config.rack.tidy.blank?
  begin
    require 'rack/contrib'
    use Rack::Tidy, :mode => Wiki::Config.rack.tidy.to_sym
  rescue
  end
end

if !Wiki::Config.rack.rewrite_base.blank?
  require 'rack/rewrite'
  use Rack::Rewrite, :base => Wiki::Config.rack.rewrite_base
end

use Rack::ESI
use Rack::CommonLogger

if env == 'deployment' || env == 'production'
  require 'rack/cache'
  use Rack::Cache,
    :verbose     => false,
    :metastore   => "file:#{File.join(Wiki::Config.cache, 'rack', 'meta')}",
    :entitystore => "file:#{File.join(Wiki::Config.cache, 'rack', 'entity')}"

  # FIXME: This is a sinatra problem
  Wiki::App.set :environment, :production
end

run Wiki::App
