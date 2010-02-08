# -*- coding: utf-8 -*-
require 'wiki/helper'
require 'wiki/cache'

module Wiki
  # An Engine renders resources
  # Engines get a resource as input and create text.
  class Engine
    include PageHelper
    include Templates

    # Engine context
    # A engine context holds the request parameters and other
    # variables used by the engines.
    # It is possible for a engine to run sub-engines. For this
    # purpose you create a subcontext which inherits the variables.
    class Context < Struct.new(:resource, :engine, :logger, :request,
                               :response, :parent, :private, :params)
      include Hooks

      alias page resource
      alias tree resource

      def initialize(attrs = {})
        update(attrs)
        self.logger  ||= Logger.new(nil)
        self.params  ||= HashWithIndifferentAccess.new
        self.private ||= HashWithIndifferentAccess.new
        invoke_hook(:initialized)
      end

      def subcontext(attrs = {})
        attrs = to_hash.merge!(attrs)
        attrs[:params] = params.merge(attrs[:params] || {})
        attrs[:private] = private.merge(attrs[:private] || {})
        attrs[:parent] = self
        Context.new(attrs)
      end

      def id
        Wiki.md5(engine.name + resource.id + params.to_a.sort.inspect)
      end
    end

    @engines = {}

    # Constructor for engine
    # Options:
    # * layout: Engine output should be wrapped in HTML layout (Not used for download/image engines for example)
    # * cacheable: Engine output can be cached
    # * priority: Engine priority. The engine with the lowest priority will be used for a resource.
    def initialize(name, opts)
      @name = name.to_s
      @layout = !!opts[:layout]
      @cacheable = !!opts[:cacheable]
      @priority = (opts[:priority] || 99).to_i
    end

    attr_reader :name, :priority
    question_reader :layout, :cacheable

    # Create engine class. This is sugar to create and
    # register an engine class in one step.
    def self.create(name, opts = {}, &block)
      engine = Class.new(Engine)
      engine.class_eval(&block) if block
      register engine.new(name, opts)
    end

    # Register engine instance
    def self.register(engine)
      (@engines[engine.name] ||= []) << engine
    end

    # Find all accepting engines for a resource
    def self.find_all(resource)
      @engines.values.flatten.find_all { |e| e.accepts? resource }.sort_by {|a| a.name }
    end

    # Find appropiate engine for resource. An optional
    # name can be given to claim a specific engine.
    # If no engine is found a exception is raised.
    def self.find!(resource, opts = {})
      opts[:name] ||= resource.metadata[:output] || resource.metadata[:engine] if !resource.meta?
      engines = opts[:name] ? @engines[opts[:name].to_s] : @engines.values.flatten
      engine = engines.to_a.sort_by {|a| a.priority }.find { |e| e.accepts?(resource) && (!opts[:layout] || e.layout?) }
      raise(RuntimeError, :engine_not_available.t(:engine => opts[:name], :page => resource.path, :mime => resource.mime)) if !engine
      engine.dup
    end

    # Find appropiate engine for resource. An optional
    # name can be given to claim a specific engine.
    # If no engine is found nil is returned.
    def self.find(resource, opts = {})
      find!(resource, opts) rescue nil
    end

    # Acceptor should return true if resource would be accepted by this engine.
    # Reimplement this method.
    def accepts?(resource); resource.respond_to? :content; end

    # Render resource content.
    # Reimplement this method.
    def output(context); context.resource.content; end

    # Get output mime type.
    # Reimplement this method.
    def mime(resource); resource.mime; end

    # Engine response. Reimplement this method
    # if you want to set response headers for example.
    def response(opts)
      render(opts)
    end

    # Render resource with caching. It should not be overwritten.
    def render(opts)
      context = Context.new(opts.merge(:engine => self))
      Cache.cache('engine', context.id,
                  :disable => context.resource.modified? || !cacheable?,
                  :update => context.request && context.request.no_cache?) { output(context) }
    end
  end
end
