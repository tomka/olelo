require 'wiki/mime'
require 'wiki/extensions'

module Wiki
  class Engine
    include Helper

    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end

    @engines = []

    attr_reader :name, :priority
    def layout?; @layout; end
    
    def initialize(name, priority, layout)
      @name = name
      @priority = priority
      @layout = layout
    end
    
    def self.create(name, priority, layout, &block)
      # @engines << Class.new(Engine, &block).new(name, priority, layout)
      @engines << engine = Engine.new(name, priority, layout)
      engine.metaclass.instance_eval(&block)
      engine
    end

    def self.find(page, name = nil)
      engine = @engines.sort {|a,b| a.priority <=> b.priority }.
        find { |e| (name.blank? || e.name == name.to_sym) && e.accepts(page) }
      return engine if engine
      raise NotAvailable.new(name)
    end

    def self.accepts(&block)
      define_method :accepts, &block
    end

    def self.output(&block)
      define_method :output, &block
    end

    def self.mime(&block)
      define_method :mime, &block
    end

    accepts {|page| false }
    output  {|page| '' }
    mime    {|page| 'text/plain' }
  end
end
