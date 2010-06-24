# -*- coding: utf-8 -*-
module Wiki
  # Wiki plugin system
  class Plugin
    include Util
    include Hooks

    @plugins = {}
    @failed = []
    @disabled = []
    @dir = ''
    @logger = nil

    class<< self
      attr_accessor :dir, :logger, :disabled

      # Current loading plugin
      def current
        file = caller.each do |line|
          return @plugins[$1] if line =~ %r{^#{@dir}/(.+?)\.rb}
        end
        raise 'No plugin context'
      end

      # Get plugin by name
      def [](name)
        @plugins[name.to_s]
      end

      # Get all plugins
      def plugins
        @plugins.values
      end

      # Get failed plugins
      def failed
        @failed
      end

      # Start plugins
      def start
        @plugins.each_value {|plugin| plugin.start }
      end

      # Load plugins by name and return a boolean for success
      def load(*list)
        files = list.map do |name|
          Dir[File.join(@dir, '**', "#{name.cleanpath}.rb")]
        end.flatten
        return false if files.empty?
        files.inject(true) do |result,file|
          name = file[(@dir.size+1)..-4]
          if @failed.include?(name) || @plugins.include?(name)
	    result
	  elsif !enabled?(name)
	    false
	  else
            begin
	      plugin = new(name, file, logger)
              plugin.with_hooks :load do
                @plugins[name] = plugin
                plugin.instance_eval(File.read(file), file)
                logger.debug("Plugin #{name} successfully loaded")
              end
            rescue Exception => ex
              @failed << name
              if LoadError === ex
                logger.error "Plugin #{name} could not be loaded due to: #{ex.message} (Missing gem?)"
              else
                logger.error "Plugin #{name} could not be loaded due to: #{ex.message}"
                logger.error ex
              end
              @plugins.delete(name)
              false
            end
	  end
        end
      end

      # Check if plugin is enabled
      def enabled?(name)
        paths = name.split(File::SEPARATOR)
        paths.inject(nil) do |path, x|
          path = path ? File.join(path, x) : x
          return false if disabled.include?(path)
          path
        end
        true
      end
    end

    attr_reader :name, :file, :started
    attr_setter :author, :description, :logger

    def initialize(name, file, logger)
      @name = name
      @file = file
      @logger = logger
      @setup = nil
      @started = false
    end

    # Add setup method
    def setup(&block)
      @setup = block
    end

    # Start the plugin
    def start
      return true if @started
      with_hooks :start do
        instance_eval(&@setup) if @setup
        @started = true
        logger.debug "Plugin #{name} successfully started"
      end
    rescue Exception => ex
      logger.error "Plugin #{name} failed to start due to: #{ex.message}"
      logger.error ex
      false
    end

    # Load specified plugins and fail if
    # dependencies are missing.
    def dependencies(*list)
      @dependencies ||= []
      @dependencies += list
      list.each do |dep|
        raise(LoadError, "Could not load dependency #{dep} for #{name}") if !Plugin.load(dep)
      end
      @dependencies
    end

    private_class_method :new
  end
end
