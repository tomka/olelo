#!/usr/bin/env rackup
# -*- coding: utf-8 -*-

path = ::File.expand_path(::File.dirname(__FILE__))
$: << ::File.join(path, 'lib')
Dir[::File.join(path, 'deps', '*', 'lib')].each {|x| $: << x }

require 'wiki/timer'
timer = Wiki::Timer.start

# Require newest rack
raise 'Rack 1.1.0 or newer required' if Rack.version < '1.1'

# We want to read all text data as UTF-8
Encoding.default_external = Encoding::UTF_8 if ''.respond_to? :encoding

require 'fileutils'
require 'rack/patches'
require 'rack/degrade_mime_type'
require 'rack/relative_redirect'
require 'rack/static_cache'
require 'wiki'

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  ::File.join(path, 'config', 'config.yml')
end

default_config = {
  :title           => 'Git-Wiki',
  :app_path        => path,
  :production      => true,
  :locale	   => 'en_US',
  :root_path       => 'Root',
  :index_page      => 'Index',
  :sidebar_page    => 'Sidebar',
  :external_images => false,
  :cache => ::File.join(path, '.wiki', 'cache'),
  :namespaces => {
    :discussion => 'Discussion:',
    :metadata   => 'Metadata:',
  },
  :authentication => {
    :service  => :yamlfile,
    :yamlfile => {
      :store  => ::File.join(path, '.wiki', 'users.yml'),
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
  :rack => {
    :blacklist    => [],
    :deflater     => true,
    :embed        => false,
    :esi          => true,
    :rewrite_base => nil,
  },
  :repository => {
    :type  => :git,
    :git => {
      :path => ::File.join(path, '.wiki', 'repository'),
    },
  },
  :log => {
    :level => 'INFO',
    :file  => ::File.join(path, '.wiki', 'log'),
  },
}

Wiki::Config.update(default_config)
Wiki::Config.load(config_file)

FileUtils.mkpath Wiki::Config.cache, :mode => 0755
FileUtils.mkpath ::File.dirname(Wiki::Config.log.file), :mode => 0755

logger = ::Logger.new(Wiki::Config.log.file, 25, 1024000)
logger.level = ::Logger.const_get(Wiki::Config.log.level)

use_lint if !Wiki::Config.production?

if !Wiki::Config.rack.blacklist.empty?
  require 'rack/blacklist'
  use Rack::Blacklist, :blacklist => Wiki::Config.rack.blacklist
end

use(Rack::Config) {|env| env['rack.logger'] = logger }
use Rack::DegradeMimeType
use Rack::RelativeRedirect

if !Wiki::Config.rack.rewrite_base.blank?
  logger.info "Use rack rewrite base=#{Wiki::Config.rack.rewrite_base}"
  require 'rack/rewrite'
  use Rack::Rewrite, :base => Wiki::Config.rack.rewrite_base
end

if Wiki::Config.rack.deflater?
  logger.info 'Use rack deflater'
  use Rack::Deflater
end

use Rack::StaticCache, :urls => ['/static'], :root => path

use Rack::Session::Pool

if Wiki::Config.rack.embed?
  logger.info 'Use rack image embedding'
  require 'rack/embed'
  use Rack::Embed, :threaded => true
end

if Wiki::Config.rack.esi?
  logger.info 'Use rack esi'
  require 'rack/esi'
  use Rack::ESI

  if Wiki::Config.production?
    logger.info 'Use rack cache'
    require 'rack/cache'
    require 'rack/purge'
    use Rack::Purge
    use Rack::Cache,
      :verbose     => false,
      :metastore   => "file:#{::File.join(Wiki::Config.cache, 'rack', 'meta')}",
      :entitystore => "file:#{::File.join(Wiki::Config.cache, 'rack', 'entity')}"
  end
end

class LoggerOutput
  def initialize(logger); @logger = logger; end
  def write(text); @logger << text; end
end

use Rack::MethodOverride
use Rack::CommonLogger, LoggerOutput.new(logger)
run Wiki::Application.new(nil, :logger => logger)

logger.info "Wiki started in #{timer.stop.elapsed_ms}ms (#{Wiki::Config.production? ? 'Production' : 'Development'} mode)"
