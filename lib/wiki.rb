# -*- coding: utf-8 -*-

require 'logger'
require 'cgi'
require 'digest/md5'
require 'digest/sha2'
require 'open3'

autoload 'YAML', 'yaml'

gem 'nokogiri', '>= 1.4.1'
autoload 'Nokogiri', 'nokogiri'

gem 'mimemagic', '>= 0.1.1'
autoload 'MimeMagic', 'mimemagic'

gem 'haml', '>= 3.0.4'
autoload 'Haml', 'haml'

require 'wiki/extensions'
require 'wiki/util'
require 'wiki/i18n'
require 'wiki/hooks'
require 'wiki/timer'
require 'wiki/config'
require 'wiki/routing'
require 'wiki/user'
require 'wiki/helper'
require 'wiki/templates'
require 'wiki/resource'
require 'wiki/plugin'
require 'wiki/application'
