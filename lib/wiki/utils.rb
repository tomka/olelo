require 'wiki/extensions'
require 'haml'
require 'sass'
require 'yaml'
require 'cgi'

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
    SASS_OPTIONS = { :style => :compat }

    class << self
      lazy_reader(:paths) { [File.join(Config.root, 'views')] }
      lazy_reader :template_cache, {}
    end

    def sass(name, opts = {})
      template = Symbol === name ? lookup_template(:sass, name) : name
      name = Symbol === name ? "#{name}.sass" : 'inline sass'
      sass_opts = SASS_OPTIONS.merge(opts[:options] || {}).merge(:filename => name)
      engine = ::Sass::Engine.new(template, sass_opts)
      engine.render
    end

    def haml(name, opts = {})
      output = render_haml(name, opts)
      output = render_haml(:layout, opts) { output } if opts[:layout] != false
      output
    end

    private

    def render_haml(name, opts = {}, &block)
      template = Symbol === name ? lookup_template(:haml, name) : name
      name = Symbol === name ? "#{name}.haml" : 'inline haml'
      haml_opts = HAML_OPTIONS.merge(opts[:options] || {}).merge(:filename => name)
      engine = ::Haml::Engine.new(template, haml_opts)
      engine.render(self, opts[:locals] || {}, &block)
    end

    def lookup_template(type, name)
      if Config.production?
        Templates.template_cache["#{type}-#{name}}"] ||= load_template(type, name)
      else
        load_template(type, name)
      end
    end

    def load_template(type, name)
      paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
      File.read(paths.find {|path| File.exists?(path) })
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
