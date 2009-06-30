require 'wiki/extensions'
require 'wiki/utils'
require 'wiki/cache'

module Wiki
  # An Engine renders pages
  class Engine
    include Helper
    include Templates

    class Context < Hash
      attr_reader :page, :engine

      def initialize(engine, page, params)
        merge!(params)
        @engine = engine
        @page = page
      end

      def subcontext(params = {})
        sub = Context.new(params.delete(:engine) || @engine, params.delete(:page) || @page, self)
        sub.merge!(params)
        sub
      end

      def id
        Digest::MD5.hexdigest(@engine.name + page.sha + inspect)
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
    question_accessor :layout, :cacheable

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

    # Find appropiate engine for page. An optional
    # name can be given to claim a specific engine.
    def self.find(page, name = nil)
      name = name.to_s

      engine = if name.blank?
        @engines.values.sort {|a,b| a.priority <=> b.priority }.find { |e| e.accepts? page }
      else
        e = @engines[name]
        e && e.accepts?(page) ? e : nil
      end

      return engine.dup if engine
      nil
    end

    def self.find!(page, name = nil)
      find(page, name) || raise(RuntimeError, :engine_not_available.t(name, page.path, page.mime))
    end

    # Acceptor should return true if page would be accepted by this engine
    def accepts?(page); true; end

    # Render page content
    def output(context); context.page.content; end

    # Get output mime type
    def mime(page); page.mime; end

    # Render page with caching. This is
    # the primary engine interface
    def render(page, params = {})
      context = Context.new(self, page, params)
      Cache.cache('engine', context.id, :disable => !page.saved? || !cacheable?) { output(context) }
    end
  end

  # Raw engine
  Engine.register(Engine.new(:raw, :priority => 999, :layout => false))
end
