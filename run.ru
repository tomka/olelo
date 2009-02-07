#!/usr/bin/env rackup
require 'wiki'

config_file = File.expand_path(File.join(File.dirname(__FILE__), 'config.yml'))
Wiki::App.set :config, YAML.load_file(config_file)
run Wiki::App

