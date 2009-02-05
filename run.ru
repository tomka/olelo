#!/usr/bin/env rackup
require 'wiki'
Wiki::App.set :repository, File.expand_path(File.join(File.dirname(__FILE__), 'repository'))
run Wiki::App