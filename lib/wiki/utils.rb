require 'wiki/extensions'
require 'haml'
require 'sass'

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

  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }
    SASS_OPTIONS = { :style => :compat }

    def sass(name, opts = {})
      sass_opts = SASS_OPTIONS.merge(opts[:options] || {})
      engine = ::Sass::Engine.new(opts[:direct] ? name : lookup_template(:sass, name), sass_opts)
      engine.render
    end

    def haml(name, opts = {})
      output = render_haml(name, opts)
      output = render_haml('layout', opts) { output } if opts[:layout] != false
      output
    end

    private

    def render_haml(name, opts = {}, &block)
      haml_opts = HAML_OPTIONS.merge(opts[:options] || {})
      engine = ::Haml::Engine.new(opts[:direct] ? name : lookup_template(:haml, name), haml_opts)
      engine.render(self, opts[:locals] || {}, &block)
    end

    def lookup_template(type, name)
      @template_cache ||= {}
      @template_cache[type] ||= {}
      @template_cache[type][name.to_s] ||= File.read(File.join(Config.root, 'views', "#{name}.#{type}"))
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
