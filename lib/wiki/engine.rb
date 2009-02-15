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

    @engines = {}

    attr_reader :name, :priority
    def layout?; @layout; end
    
    def initialize(name, priority, layout)
      @name = name
      @priority = priority
      @layout = layout
    end

    def self.extend(name, &block)
      name = name.to_s
      raise ArgumentError.new("Engine #{name} not found") if !@engines.key?(name)
      @engines[name].metaclass.instance_eval(&block)
    end

    def self.create(name, priority, layout, &block)
      name = name.to_s
      raise ArgumentError.new("Engine #{name} already exists") if @engines.key?(name)
      @engines[name] = engine = new(name, priority, layout)
      engine.metaclass.instance_eval(&block)
      engine
    end

    def self.find(page, name = nil)
      name = name.to_s

      engine = if name.blank?
        @engines.values.sort {|a,b| a.priority <=> b.priority }.find { |e| e.accepts? page }
      else
        e = @engines[name]
        e.accepts?(page) ? e : nil
      end

      return engine if engine
      raise NotAvailable.new(name)
    end

    def self.method_missing(name, &block)
      define_method name, &block
    end

    def self.accepts(&block)
      define_method :accepts?, &block
    end

    accepts {|page| false }
    output  {|page| filter(page, page.content.dup).last }
    filter  {|page,content| [page, content] }
    mime    {|page| 'text/plain' }

    private_class_method :new
  end
end
