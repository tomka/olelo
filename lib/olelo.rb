require 'logger'
require 'cgi'
require 'digest/md5'
require 'digest/sha2'
require 'open3'
require 'set'
require 'yaml'
require 'mimemagic'
require 'haml'

# Nokogiri uses dump_html instead of serialize for broken libxml versions
# Unfortunately this breaks some things here.
# FIXME: Remove this check as soon as nokogiri works correctly.
require 'nokogiri'
raise 'The libxml version used by nokogiri is broken, upgrade to 2.7' if %w[2 6] === Nokogiri::LIBXML_VERSION.split('.')[0..1]

require 'olelo/compatibility'
require 'olelo/extensions'
require 'olelo/util'
require 'olelo/i18n'
require 'olelo/hooks'
require 'olelo/timer'
require 'olelo/config'
require 'olelo/routing'
require 'olelo/user'
require 'olelo/fs'
require 'olelo/templates'
require 'olelo/helper'
require 'olelo/attributeeditor'
require 'olelo/page'
require 'olelo/plugin'
require 'olelo/patch'
require 'olelo/initializer'
require 'olelo/application'
