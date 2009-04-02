#!/usr/bin/env rackup

ENV['RACK_ENV'] = env

path = File.expand_path(File.dirname(__FILE__))

$: << File.join(path, 'lib') << File.join(path, 'deps/sinatra/lib')
require 'wiki/config'

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  File.join(path, 'config.yml')
end

default_config = {
  :title        => 'Git-Wiki',
  :root         => path,
  :store        => File.join(path, '.wiki', 'store.yml'),
  :cache        => File.join(path, '.wiki', 'cache'),
  :default_mime => 'text/x-creole',
  :main_page    => 'Home',
  :disabled_plugins => ['misc/private_wiki'],
  :rack => {
    :rewrite_base => nil,
    :profiling    => false,
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

require 'rack/path_info'
use Rack::PathInfo

if Wiki::Config.rack.profiling
  require 'rack/contrib'
  use Rack::Profiler, :printer => :graph
end

if !Wiki::Config.rack.rewrite_base.blank?
  require 'rack/rewrite'
  use Rack::Rewrite, :base => Wiki::Config.rack.rewrite_base
end

# FIXME: Problem with fastcgi handler
if server == 'fastcgi'
  options.delete :File
  options.delete :Port
end

use Rack::Session::Pool

require 'wiki/app'
run Wiki::App
