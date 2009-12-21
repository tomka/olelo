# -*- coding: utf-8 -*-
require 'wiki/extensions'
require 'yaml'
require 'cgi'

gem 'haml', '>= 2.2.0'
require 'haml/helpers'
module Haml::Helpers
  # Remove stupid deprecated helper
  remove_method :puts

  alias original_capture_haml capture_haml

  # Encoding problem with haml
  def capture_haml(*args, &block)
    Wiki.set_encoding(original_capture_haml(*args, &block))
  end
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

    def initialize(*messages)
      @messages = messages
    end

    def message
      @messages.join("\n")
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
      base.class_eval { include InstanceMethods }
    end

    module InstanceMethods
      def with_hooks(type, *args)
        result = []
        begin
          result += invoke_hook(:"before_#{type}", *args) << yield
        ensure
          result += invoke_hook(:"after_#{type}", *args)
        end
        result
      end

      def invoke_hook(type, *args)
        self.class.invoke_hook(self, type, *args)
      end

      def output_with_hooks(type, *args)
        if block_given?
          with_hooks(type, *args, &block).map(&:to_s).join
        else
          invoke_hook(type, *args, &block).to_s.join
        end
      rescue => ex
        %{<span class="error">#{ex.message}</span>}
      end
    end

    module ClassMethods
      lazy_reader :hooks, {}

      def hook(type, &block)
        (hooks[type] ||= []) << block.to_method(self)
      end

      def invoke_hook(source, type, *args)
        result = []
        while type
          result += hooks[type].to_a.map {|method| method.bind(source).call(*args) }
          break if type == Object || hooks[type]
          type = type.superclass rescue nil
        end
        result
      end
    end
  end

  class Semaphore
    def initialize(counter = 1)
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @counter = counter
    end

    def enter
      @mutex.synchronize do
        @cond.wait(@mutex) if (@counter -= 1) < 0
      end
    end

    def leave
      @mutex.synchronize do
        @cond.signal if (@counter += 1) <= 0
      end
    end

    def synchronize
      enter
      yield
    ensure
      leave
    end
  end

  class<< self
    def forbid(conds)
      failed = conds.keys.select {|key| conds[key] }
      raise(Wiki::MultiError, *failed) if !failed.empty?
    end

    def html_escape(text)
      CGI.escapeHTML(text.to_s)
    end

    def html_unescape(text)
      CGI.unescapeHTML(text.to_s)
    end

    def set_encoding(object)
      object.respond_to?(:force_encoding) ? object.force_encoding(__ENCODING__) : object
    end
  end
end

class Symbol
  def t(args = {})
    Wiki::I18n.translate(self, args)
  end
end
