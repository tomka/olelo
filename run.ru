#!/usr/bin/env rackup
require 'wiki'

# FIXME
REPOSITORY_BASE = File.join(File.dirname(__FILE__), 'repository')
run Wiki::App
