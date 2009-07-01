require 'wiki/extensions'
require 'haml'
require 'sass'
require 'yaml'

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
          lang = Config.locale
          locale = load(path, lang)
          locale.merge!(load(path, $1)) if lang =~ /^(\w+)-\w+$/
          @locale.merge!(locale)
          @loaded << path
        end
      end

      def translate(key, args = {})
        args = args.with_indifferent_access
        if @locale[key]
          @locale[key].gsub(/\{\{(\w+)\}\}/) {|x| args[$1] || x }
        else
          "##{key}"
        end
      end

      private

      def load(path, lang)
        YAML.load_file(File.join(path, "#{lang}.yml")) rescue {}
      end
    end
  end

  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }
    SASS_OPTIONS = { :style => :compat }

    class << self
      attr_reader_with_default :paths => lambda { [File.join(Config.root, 'views')] }
      attr_reader_with_default :template_cache => {}
    end

    def sass(name, opts = {})
      sass_opts = SASS_OPTIONS.merge(opts[:options] || {})
      engine = ::Sass::Engine.new(Symbol === name ? lookup_template(:sass, name) : name, sass_opts)
      engine.render
    end

    def haml(name, opts = {})
      output = render_haml(Symbol === name ? lookup_template(:haml, name) : name, opts)
      output = render_haml(lookup_template(:haml, 'layout'), opts) { output } if opts[:layout] != false
      output
    end

    private

    def render_haml(template, opts = {}, &block)
      haml_opts = HAML_OPTIONS.merge(opts[:options] || {})
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
        self.class.invoke_hook(self, type, *args)
      end

      def content_hook(type, *args)
        invoke_hook(type, *args).map(&:to_s).join
      rescue => ex
        "<span class=\"error\">#{escape_html ex.message}</span>"
      end
    end

    module ClassMethods
      def add_hook(type, &block)
        @hooks ||= {}
        (@hooks[type] ||= []) << block
      end

      def invoke_hook(source, type, *args)
        @hooks ||= {}
        result = []
        while type
          result += @hooks[type].to_a.map {|block| source.instance_exec(*args, &block) }
          break if type == Object || @hooks[type]
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
