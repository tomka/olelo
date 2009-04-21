#!/usr/bin/env rackup

ENV['RACK_ENV'] = env

path = ::File.expand_path(::File.dirname(__FILE__))

$LOAD_PATH << ::File.join(path, 'lib')
Dir[::File.join(path, 'deps', '*', 'lib')].each {|x| $: << x }

require 'wiki/app'
require 'rack/path_info'
require 'rack/esi'
require 'rack/session/pstore'
require 'fileutils'
require 'logger'

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  ::File.join(path, 'config.yml')
end

# FIXME: Problem with fastcgi handler
if server == 'fastcgi'
  options.delete :File
  options.delete :Port
end

default_config = {
  :title        => 'Git-Wiki',
  :root         => path,
  :auth => {
    :service => 'yamlfile',
    :store   => ::File.join(path, '.wiki', 'users.yml'),
  },
  :cache        => ::File.join(path, '.wiki', 'cache'),
  :default_mime => 'text/x-creole',
  :main_page    => 'Home',
  :disabled_plugins => ['misc/private_wiki'],
  :rack => {
    :rewrite_base => nil,
    :profiling    => false,
    :tidy         => nil
  },
  :git => {
    :repository => ::File.join(path, '.wiki', 'repository'),
    :workspace  => ::File.join(path, '.wiki', 'workspace'),
  },
  :log => {
    :level => 'INFO',
    :file  => ::File.join(path, '.wiki', 'log'),
  },
}

Wiki::Config.update(default_config)
Wiki::Config.load(config_file)

if Wiki::Config.rack.profiling
  require 'rack/contrib'
  use Rack::Profiler, :printer => :graph
end

use Rack::Session::PStore
use Rack::PathInfo
use Rack::MethodOverride

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

FileUtils.mkdir_p ::File.dirname(Wiki::Config.log.file), :mode => 0755
logger = Logger.new(Wiki::Config.log.file)
logger.level = Logger.const_get(Wiki::Config.log.level)

use Rack::ESI, :no_cache => true
use Rack::CommonLogger, logger

if env == 'deployment' || env == 'production'
  require 'rack/cache'
  use Rack::Cache,
    :verbose     => false,
    :metastore   => "file:#{::File.join(Wiki::Config.cache, 'rack', 'meta')}",
    :entitystore => "file:#{::File.join(Wiki::Config.cache, 'rack', 'entity')}"

  # FIXME: This is a sinatra problem
  Wiki::App.set :environment, :production
end

use Rack::Static, :urls => ['/static'], :root => path
run Wiki::App.new(nil, :logger => logger)

