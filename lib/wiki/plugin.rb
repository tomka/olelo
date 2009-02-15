require 'wiki/utils'

module Wiki
  class Plugin
    include Utils
    
    @plugins = {}
    @dir = ''
    @logger = nil

    class<< self
      attr_reader :plugins
      attr_accessor :dir, :logger

      def define(name, &block)
        if !@plugins.key?(name)
          name = name.to_s
          plugin = new(name)
          plugin.instance_eval(&block)
          @plugins[name] = plugin
        end
      rescue Exception => ex
        @logger.error(ex) if @logger
      end

      def load_all
        Dir.glob(File.join(@dir, "**/*.rb")).each {|x| safe_require x }
      end

      def load(name)
        name = name.to_s
        if !@plugins.key?(name)
          file = Dir.glob(File.join(@dir, "**/#{name}.rb")).first
          file && safe_require(file)
        end
      end
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def depends_on(*list)
      list.each do |x|
        raise RuntimeError.new("Could not load dependency #{x}") if !Plugin.load(x)
      end
    end

    private_class_method :new
  end
end
