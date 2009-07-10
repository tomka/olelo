require 'wiki/utils'
require 'pathname'

module Wiki
  # Wiki plugin system
  class Plugin
    @plugins = {}
    @dir = ''
    @logger = nil

    class<< self
      attr_reader :plugins
      attr_accessor :dir, :logger

      # Start plugins
      def start
        @plugins.each_value {|plugin| plugin.start }
      end

      # Load plugins by name and return a boolean for success
      def load(*list)
        dir = File.join(Config.root, 'plugins')
        files = list.map do |name|
          name = Pathname.new(name).cleanpath
          Dir.glob(File.join(dir, '**', "#{name}.rb"))
        end.flatten
        return false if files.empty?
        files.inject(true) do |result,file|
          begin
            name = file[(dir.size+1)..-4]
            if !@plugins.include?(name) && enabled?(name)
              plugin = new(name, @logger)
              plugin.instance_eval(File.read(file), file)
              I18n.load_locale(file.sub(/\.rb$/, '_LANG.yml'))
              I18n.load_locale(File.join(File.dirname(file), 'locale', 'LANG.yml'))
              Templates.paths << File.dirname(file)
              @plugins[name] = plugin
              @logger.debug("Plugin #{name} successfully loaded")
            end
            result
          rescue Exception => ex
            @logger.error ex
            false
          end
        end
      end

      # Check if plugin is enabled
      def enabled?(name)
        paths = name.split(File::SEPARATOR)
        paths.inject(nil) do |path, x|
          path = path ? File.join(path, x) : x
          return false if Config.disabled_plugins.to_a.include?(path)
          path
        end
        true
      end
    end

    attr_reader :name, :logger, :started

    def initialize(name, logger)
      @name = name
      @logger = logger
      @setup = []
      @started = false
    end

    # Add setup method
    def setup(&block)
      @setup << block
    end

    # Start the plugin
    def start
      return true if @started
      success = @setup.all? do |setup|
        begin
          self.instance_eval(&setup)
          true
        rescue Exception => ex
          Plugin.logger.error ex
          false
        end
      end
      @started = true
      if success
        Plugin.logger.info("Plugin #{name} successfully started")
      else
        Plugin.logger.error("Plugin #{name} failed to start")
      end
      success
    end

    # Load specified plugins.
    # This method can be used to specify optional
    # dependencies which should be loaded before this plugin.
    def load(*list)
      Plugin.load(*list)
    end

    # Load specified plugins and fail if
    # dependencies are missing.
    def depends_on(*list)
      list.each do |dep|
        raise(RuntimeError, "Could not load dependency #{dep} for #{name}") if !Plugin.load(dep)
      end
    end

    private_class_method :new

  end
end
