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
    
    attr_reader :name, :priority
    def layout?; @layout; end
    
    def initialize(name, priority, layout)
      @name = name
      @priority = priority
      @layout = layout
    end
    
    def self.create(name, priority, layout, &block)
      ENGINES << Class.new(Engine, &block).new(name, priority, layout)
    end

    def self.find(page, name = nil)
      engine = ENGINES.sort {|a,b| a.priority <=> b.priority }.
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

    private

    ENGINES = []
  end
end
