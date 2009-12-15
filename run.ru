#!/usr/bin/env rackup
# -*- coding: utf-8 -*-

env ||= ENV['RACK_ENV'] || 'development'

path = ::File.expand_path(::File.dirname(__FILE__))

$LOAD_PATH << ::File.join(path, 'lib')
Dir[::File.join(path, 'deps', '*', 'lib')].each {|x| $: << x }

require 'rubygems'
require 'fileutils'
require 'logger'
require 'rack/patched_request'
require 'rack/reverseip'
require 'wiki/app'

# Try to load server gem
gem(server, '>= 0') rescue nil

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  ::File.join(path, 'config.yml')
end

default_config = {
  :title        => 'Git-Wiki',
  :root         => path,
  :production   => false,
  :locale	=> 'en_US',
  :auth => {
    :service => 'yamlfile',
    :store   => ::File.join(path, '.wiki', 'users.yml'),
  },
  :cache        => ::File.join(path, '.wiki', 'cache'),
  :mime => {
    :default => 'text/x-creole',
    :magic   => true,
  },
  :main_page    => 'Home',
  :disabled_plugins => [
    'authorization/private_wiki',
    'tagging',
    'filter/orgmode',
    'tag/math-ritex',
    'tag/math-itex2mml',
#   'tag/math-imaginator',
  ],
  :rack => {
    :esi          => true,
    :embed        => false,
    :rewrite_base => nil,
    :profiling    => false,
    :deflater     => true,
  },
  :git => {
    :repository => ::File.join(path, '.wiki', 'repository'),
  },
  :log => {
    :level => 'INFO',
    :file  => ::File.join(path, '.wiki', 'log'),
  },
}

Wiki::Config.update(default_config)
Wiki::Config.load(config_file)

if Wiki::Config.rack.profiling?
  gem 'rack-contrib', '>= 0'
  require 'rack/contrib'
  use Rack::Profiler, :printer => :graph
end

use Rack::Session::Pool
use Rack::ReverseIP
use Rack::MethodOverride

if Wiki::Config.rack.deflater?
  require 'rack/deflater'
  use Rack::Deflater
end

if Wiki::Config.rack.embed?
  gem 'rack-embed', '>= 0'
  require 'rack/embed'
  use Rack::Embed, :threaded => true
end

if Wiki::Config.rack.esi?
  gem 'minad-rack-esi', '>= 0'
  require 'rack/esi'
  use Rack::ESI

  if env == 'deployment' || env == 'production'
    gem 'rack-cache', '>= 0.5.2'
    require 'rack/cache'
    require 'rack/purge'
    use Rack::Purge
    use Rack::Cache,
      :verbose     => false,
      :metastore   => "file:#{::File.join(Wiki::Config.cache, 'rack', 'meta')}",
      :entitystore => "file:#{::File.join(Wiki::Config.cache, 'rack', 'entity')}"
    Wiki::Config.production = true
  end
end

if !Wiki::Config.rack.rewrite_base.blank?
  require 'rack/rewrite'
  use Rack::Rewrite, :base => Wiki::Config.rack.rewrite_base
end

FileUtils.mkdir_p ::File.dirname(Wiki::Config.log.file), :mode => 0755
logger = Logger.new(Wiki::Config.log.file)
logger.level = Logger.const_get(Wiki::Config.log.level)

use Rack::CommonLogger, logger

use Rack::Static, :urls => ['/static'], :root => path
run Wiki::App.new(nil, :logger => logger)
