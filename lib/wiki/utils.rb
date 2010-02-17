# -*- coding: utf-8 -*-
require 'wiki/extensions'
require 'yaml'
require 'cgi'
require 'digest/md5'
require 'digest/sha2'

gem 'haml', '>= 2.2.16'
require 'haml/helpers'
module Haml::Helpers
  # Remove stupid deprecated helper
  remove_method :puts
end

module Haml
  autoload 'Engine', 'haml/engine'
  autoload 'Util', 'haml/util'
end

gem 'mimemagic', '>= 0.1.1'
autoload 'MimeMagic', 'mimemagic'

module Wiki
  class MultiError < StandardError
    attr_accessor :messages

    def initialize(messages)
      @messages = messages
    end

    def message
      @messages.join(', ')
    end
  end

  class BlockFile < ::File
    alias to_path path

    def each
      rewind
      while part = read(8192)
        yield part
      end
    end
  end

  module I18n
    @locale = Hash.with_indifferent_access
    @loaded = []

    class << self
      def load_locale(path)
        if !@loaded.include?(path)
          locale = YAML.load_file(path)
          @locale.update(locale[$1] || {}) if Config.locale =~ /^(\w+)(_|-)/
          @locale.update(locale[Config.locale] || {})
          @loaded << path
        end
      rescue
        nil
      end

      def translate(key, args = {})
        args = args.with_indifferent_access
        if @locale[key]
          @locale[key].gsub(/#\{(\w+)\}/) {|x| args.include?($1) ? args[$1].to_s : x }
        else
          "##{key}"
        end
      end
    end
  end

  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class << self
      lazy_reader(:paths) { [File.join(Config.root, 'views')] }
      lazy_reader :template_cache, {}
    end

    def haml(name, opts = {})
      output = render_haml(name, opts)
      output = render_haml(:layout, opts) { output } if opts[:layout] != false
      output
    end

    private

    def render_haml(name, opts = {}, &block)
      haml_opts = HAML_OPTIONS.merge(opts[:options] || {}).merge(:filename => Symbol === name ? "#{name}.haml" : 'inline haml')
      engine = load_template(:haml, name, haml_opts) { |content, opt| Haml::Engine.new(content, opt) }
      engine.render(self, opts[:locals] || {}, &block)
    end

    def load_template(type, name, opts)
      if Config.production?
        id = [type,name,opts]
        return Templates.template_cache[id] if Templates.template_cache[id]
      end

      content = if Symbol === name
                  paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
                  path = paths.find {|p| File.exists?(p) }
                  raise RuntimeError, "Template #{name} not found" if !path
                  File.read(path)
                else
                  name
                end

      template = yield(content, opts)

      if Config.production?
        id = [type,name,opts]
        Templates.template_cache[id] = template
      end

      template
    end
  end

  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    class Result < Array
      def to_s
        map(&:to_s).join
      end
    end

    def with_hooks(type, *args)
      result = Result.new
      result.push(*invoke_hook(:"before_#{type}", *args))
      result << yield
    ensure
      result.push(*invoke_hook(:"after_#{type}", *args))
    end

    def invoke_hook(type, *args)
      self.class.invoke_hook(self, type, *args)
    end

    module ClassMethods
      lazy_reader :hooks, {}

      def hook(type, priority = 0, &block)
        (hooks[type] ||= []) << [-priority, block.to_method(self)]
      end

      def invoke_hook(source, type, *args)
        result = Result.new
        while type
          result.push(*hooks[type].to_a.sort_by(&:first).map {|priority, method| method.bind(source).call(*args) })
          break if type == Object
          type = type.superclass rescue nil
        end
        result
      end
    end
  end

  class<< self
    def error(msg)
      raise RuntimeError, msg
    end

    def check()
      errors = []
      yield(errors)
      raise MultiError, errors if !errors.empty?
    end

    # Like CGI.escape but escapes space not as +
    def uri_escape(s)
      s.gsub(/([^a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end

    # Like CGI.unescape but does not unescape +
    def uri_unescape(s)
      enc = s.encoding
      s.gsub(/((?:%[0-9a-fA-F]{2})+)/) do
        [$1.delete('%')].pack('H*').force_encoding(enc)
      end
    end

    def backslash_unescape(s)
      enc = s.encoding
      s.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr.force_encoding(enc) }.
        gsub(/\\x([\da-f]{2})/i) { $1.to_i(16).chr.force_encoding(enc) }
    end

    def html_escape(text)
      CGI.escapeHTML(text.to_s)
    end

    def html_unescape(text)
      CGI.unescapeHTML(text.to_s)
    end

    def md5(s)
      Digest::MD5.hexdigest(s)
    end

    def sha256(s)
      Digest::SHA256.hexdigest(s)
    end

    def build_query(params)
      params.map do |k, v|
        if v.class == Array
          build_query(v.map { |x| [k, x] })
        else
          "#{uri_escape(k.to_s)}=#{uri_escape(v.to_s)}"
        end
      end.join('&')
    end
  end
end

class Symbol
  def t(args = {})
    Wiki::I18n.translate(self, args)
  end
end
