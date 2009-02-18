require 'wiki/mime'
require 'wiki/extensions'
require 'wiki/aspect'
require 'wiki/utils'

module Wiki
  class Engine
    include Helper
    extend Aspect

    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end

    @engines = {}

    attr_reader :name, :priority

    def layout?; @layout; end
    def cacheable?; @cacheable; end
    
    def initialize(name, opts = {})
      @name = name
      @priority = opts[:priority] || 0
      @layout = opts[:layout] || false
      @cacheable = opts[:cacheable] || false
    end

    def self.enhance(*names, &block)
      names.each do |name|
        name = name.to_s
        @engines.key?(name) && @engines[name].metaclass.instance_eval(&block)
      end
    end

    def self.create(name, opts = {}, &block)
      name = name.to_s
      raise ArgumentError.new("Engine #{name} already exists") if @engines.key?(name)
      @engines[name] = engine = new(name, opts)
      engine.metaclass.instance_eval(&block)
      engine
    end

    def self.find(page, name = nil)
      name = name.to_s

      engine = if name.blank?
        @engines.values.sort {|a,b| a.priority <=> b.priority }.find { |e| e.accepts? page }
      else
        e = @engines[name]
        e && e.accepts?(page) ? e : nil
      end

      return engine if engine
      raise NotAvailable.new(name)
    end

    def render(page)
      Cache.cache('engine', name + page.sha, :disable => !page.saved? || !cacheable?) { output page }
    end

    def self.output(&block);  define_method :output, &block;   end
    def self.filter(&block);  define_method :filter, &block;   end
    def self.mime(&block);    define_method :mime, &block;     end
    def self.accepts(&block); define_method :accepts?, &block; end
    
    accepts {|page| false }
    output  {|page| filter(page, page.content.dup).last }
    filter  {|page,content| [page, content] }
    mime    {|page| 'text/plain' }

    private_class_method :new
  end
end
