require 'wiki/mime'
require 'wiki/extensions'
require 'wiki/utils'

module Wiki
  # An Engine renders pages
  class Engine
    include Helper

    # Error which is raised if no appropiate engine is found
    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end

    class Context < Hash
      attr_reader :page, :engine, :level

      def initialize(engine, page, params, level = 0)
        merge!(params)
        @engine = engine
        @page = page
        @level = level
      end

      def subcontext(params = {})
        sub = Context.new(params.delete(:engine) || @engine, params.delete(:page) || @page, self, level + 1)
        sub.merge!(params)
        sub
      end

      def id
        Digest::MD5.hexdigest(@engine.name + page.sha + inspect)
      end
    end

    # FIXME: Double implementation
    def haml(name, options = {})
      engine = ::Haml::Engine.new(File.read(File.join(Config.root, 'views', "#{name}.haml")), options[:options] || {})
      engine.render(self, options[:locals] || {})
    end

    @engines = {}

    def initialize(name, layout, cacheable, priority)
      @name = name.to_s
      @layout = layout
      @cacheable = cacheable
      @priority = priority
    end

    attr_reader :name, :priority
    question_accessor :layout, :cacheable

    # Create engine class. This is sugar to create and
    # register an engine class in one step.
    def self.create(name, opts = {}, &block)
      engine = Class.new(Engine)
      engine.class_eval(&block)
      register engine.new(name, !!opts[:layout], !!opts[:cacheable], opts[:priority].to_i)
    end

    def self.register(engine)
      raise(ArgumentError, "Engine #{engine.name} already exists") if @engines.key?(engine.name)
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
      raise NotAvailable, name
    end

    # Sugar to generate methods
    def self.output(&block);  define_method :output, &block;   end
    def self.mime(&block);    define_method :mime, &block;     end
    def self.accepts(&block); define_method :accepts?, &block; end

    # Acceptor should return true if page would be accepted by this engine
    accepts {|page| false }

    # Render page content
    output {|context| context.page.content.dup }

    # Get output mime type
    mime {|page| 'text/plain' }

    # Render page with caching. This is
    # the primary engine interface
    def render(page, params = {})
      context = Context.new(self, page, params)
      Cache.cache('engine', context.id, :disable => !page.saved? || !cacheable?) { output(context) }
    end
  end
end
