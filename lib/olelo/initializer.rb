module Olelo
  class Initializer
    include Util

    def self.init(logger)
      @instance ||= Initializer.new(logger)
    end

    def initialize(logger)
      @logger = logger
      self.class.private_instance_methods.each do |name|
        send(name) if name.to_s.begins_with? 'init_'
      end
    end

    private

    class TemplateLoader
      def context
        Plugin.current.name rescue nil
      end

      def load(name)
        plugin = Plugin.current rescue nil
        fs = []
        fs << DirectoryFS.new(File.dirname(plugin.file)) << InlineFS.new(plugin.file) if plugin
        fs << DirectoryFS.new(Config.views_path)
        UnionFS.new(*fs).read(name)
      end
    end

    def init_locale
      I18n.locale = Config.locale
      I18n.load(File.join(File.dirname(__FILE__), 'locale.yml'))
    end

    def init_templates
      Templates.enable_caching if Config.production?
      Templates.loader = TemplateLoader.new
    end

    def init_plugins
      # Load locales for loaded plugins
      Plugin.after(:load) { I18n.load(File.join(File.dirname(file), 'locale.yml')) }

      # Configure plugin system
      Plugin.logger = @logger
      Plugin.disabled = Config.disabled_plugins.to_a
      Plugin.dir = Config.plugins_path

      # Load all plugins
      Plugin.load('*')
      Plugin.start
    end

    def init_themes
      default = File.basename(File.readlink(File.join(Config.themes_path, 'default')))
      Application.theme_links = Dir.glob(File.join(Config.themes_path, '*', 'style.css')).map do |file|
        name = File.basename(File.dirname(file))
        path = Config.base_path + "static/themes/#{name}/style.css?#{File.mtime(file).to_i}"
        %{<link rel="#{name == default ? '' : 'alternate '}stylesheet"
          href="#{escape_html path}" type="text/css" title="#{escape_html name}"/>}.unindent if name != 'default'
      end.compact.join("\n")
    end

    def init_routes
      Application.reserved_paths = Application.router.map do |method, router|
        router.map { |name, pattern, keys| [pattern, /#{pattern.source[0..-2]}/] }
      end.flatten
      Application.final_routes
      Application.router.each do |method, router|
        @logger.debug method
        router.each do |name, pattern, keys|
          @logger.debug "#{name} -> #{pattern.inspect}"
        end
      end if @logger.debug?
    end

    def init_custom
      Dir[File.join(Config.initializers_path, '*.rb')].sort_by do |f|
        File.basename(f)
      end.each do |f|
        @logger.debug "Running custom initializer #{f}"
	instance_eval(File.read(f), f)
      end
    end
  end
end
