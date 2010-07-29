Templates.enable_caching if Config.production?
Templates.make_fs = proc do
  plugin = Plugin.current rescue nil
  fs = []
  fs << DirectoryFS.new(File.dirname(plugin.file)) << InlineFS.new(plugin.file) if plugin
  fs << DirectoryFS.new(Config.views_path)
  UnionFS.new(*fs)
end
