# -*- coding: utf-8 -*-
require 'wiki/extensions'
require 'yaml'
require 'cgi'

gem 'haml', '>= 2.2.0'
require 'haml'

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
      engine = load_template(:haml, name, haml_opts) { |content, opt| ::Haml::Engine.new(content, opt) }
      engine.render(self, opts[:locals] || {}, &block)
    end

    def load_template(type, name, opts)
      if Config.production?
        id = [type,name,opts]
        return Templates.template_cache[id] if Templates.template_cache[id]
      end

      content = if Symbol === name
                  paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
                  path = paths.find {|path| File.exists?(path) }
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
      def invoke_hook(type, *args)
        if block_given?
          result = []
          begin
            result += self.class.invoke_hook(self, :"before_#{type}", *args) << yield
          ensure
            result += self.class.invoke_hook(self, :"after_#{type}", *args)
          end
          result
        else
          self.class.invoke_hook(self, type, *args)
        end
      end

      def content_hook(type, *args, &block)
        invoke_hook(type, *args, &block).map(&:to_s).join
      rescue => ex
        "<span class=\"error\">#{ex.message}</span>"
      end
    end

    module ClassMethods
      lazy_reader :hooks, {}

      def add_hook(type, &block)
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
end

module Kernel
  def escape_html(html)
    CGI::escapeHTML(html.to_s)
  end

  def forbid(conds)
    failed = conds.keys.select {|key| conds[key] }
    raise(Wiki::MultiError, *failed) if !failed.empty?
  end
end

class Symbol
  def t(args = {})
    Wiki::I18n.translate(self, args)
  end
end
