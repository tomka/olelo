raise('Compatibility library can only be used in ruby 1.8') if RUBY_VERSION > '1.9'

require 'compatibility/encoding'
require 'compatibility/string'
require 'compatibility/io'
require 'compatibility/symbol'
require 'compatibility/object'
