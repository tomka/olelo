require 'wiki/extensions'
require 'wiki/utils'
require 'wiki/cache'

module Wiki
  # An Engine renders resources
  class Engine
    include Helper
    include Templates

    class Context < Hash
      attr_reader :resource, :engine
      alias page resource
      alias tree resource

      def initialize(engine, resource, params)
        merge!(params)
        @engine = engine
        @resource = resource
      end

      def subcontext(params = {})
        sub = Context.new(params.delete(:engine) || @engine,
                          params.delete(:resource) || params.delete(:page) || params.delete(:tree) || @resource, self)
        sub.merge!(params)
        sub
      end

      def id
        Digest::MD5.hexdigest(@engine.name + resource.sha + inspect)
      end
    end

    @engines = {}

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
      engine.class_eval(&block)
      register engine.new(name, opts)
    end

    def self.register(engine)
      raise(ArgumentError, "Engine '#{engine.name}' already exists") if @engines.key?(engine.name)
      @engines[engine.name] = engine
    end

    # Find appropiate engine for resource. An optional
    # name can be given to claim a specific engine.
    def self.find(resource, name = nil)
      name ||= resource.metadata[:engine]

      engine = if !name
        @engines.values.sort {|a,b| a.priority <=> b.priority }.find { |e| e.accepts? resource }
      else
        e = @engines[name.to_s]
        e if e && e.accepts?(resource)
      end

      engine.dup if engine
    end

    def self.find!(resource, name = nil)
      find(resource, name) ||
        raise(RuntimeError, :engine_not_available.t(:engine => name, :page => resource.path, :mime => resource.mime))
    end

    # Acceptor should return true if resource would be accepted by this engine
    def accepts?(resource); resource.respond_to? :content; end

    # Render resource content
    def output(context); context.resource.content; end

    # Get output mime type
    def mime(resource); resource.mime; end

    # Render resource with caching. This is
    # the primary engine interface
    def render(resource, params = {}, update = false)
      context = Context.new(self, resource, params)
      Cache.cache('engine', context.id,
                  :disable => resource.modified? || !cacheable?,
                  :update => update) { output(context) }
    end
  end

  # Raw engine
  Engine.register(Engine.new(:raw, :priority => 999, :layout => false))
end
