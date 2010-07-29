# Load locales for loaded plugins
Plugin.after :load do
  I18n.load(file.sub(/\.rb$/, '_locale.yml'))
  I18n.load(File.join(File.dirname(file), 'locale.yml'))
end

# Configure plugin system
Plugin.logger = logger
Plugin.disabled = Config.disabled_plugins.to_a
Plugin.dir = Config.plugins_path

# Load all plugins
Plugin.load('*')

# Start loaded plugins
Plugin.start
