require 'wiki/utils'
require 'pathname'

module Wiki
  class Plugin
    @plugins = {}
    @dir = ''
    @logger = nil

    include ::Wiki

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
        load('*')
      end

      def load(name)
        name = Pathname.new(name).cleanpath
        list = Dir.glob(File.join(@dir, "**/#{name}.rb"))
        return false if list.empty?
        list.inject(true) do |result,file|
          safe_require(file) && result
        end
      end

      private

      def safe_require(name)
        require(name)
        true
      rescue Exception => ex
        @logger.error ex
        false
      end
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def load_after(*list)
      list.each do |x|
        Plugin.load(x)
      end
    end

    def depends_on(*list)
      list.each do |x|
        raise RuntimeError.new("Could not load dependency #{x}") if !Plugin.load(x)
      end
    end

    private_class_method :new

  end
end
