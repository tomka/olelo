#!/usr/bin/env rackup
require 'wiki'

def app_path(name)
  File.expand_path(File.join(File.dirname(__FILE__), 'data', name))
end

Wiki::App.set :title, 'Git-Wiki'
Wiki::App.set :repository, app_path('repository')
Wiki::App.set :workspace, app_path('workspace')
Wiki::App.set :users_store, app_path('users.yml')
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
Wiki::App.set :logger, logger
run Wiki::App

