description 'Asset manager'

class Wiki::AssetManager
  def self.assets
    @assets ||= {}
  end

  def self.scripts
    @scripts ||= {}
  end

  def self.register_assets(*files)
    base = File.dirname(Plugin.current(1).name)
    make_fs.glob(*files) {|fs, file| assets[base/file] = [fs, file] }
  end

  def self.register_scripts(*files)
    options = files.last.is_a?(Hash) ? files.pop : {}
    priority = options[:priority] || 99
    make_fs.glob(*files) do |fs, file|
      type = %w(js css).find {|ext| file.ends_with? ext }
      raise 'Invalid script type' if !type
      (scripts[type] ||= []) << [priority, fs.mtime(file), fs.read(file)]
    end
  end

  def self.make_fs
    file = Plugin.current(2).file
    UnionFS.new(Config.production? ? CacheInlineFS.new(file) : InlineFS.new(file), DirectoryFS.new(File.dirname(file)))
  end

  private_class_method :make_fs
end

class Wiki::Application
  hook :layout do |name, doc|
    doc.css('head').first << '<link rel="stylesheet" href="/_/assets/assets.css" type="text/css"/>' if AssetManager.assets['assets.css']
    doc.css('body').first << '<script src="/_/assets/assets.js" type="text/javascript"/>' if AssetManager.assets['assets.js']
  end

  get "/_/assets/:name", :name => '.*' do
    if asset = AssetManager.assets[params[:name]]
      fs, file, mtime = asset
      cache_control :last_modified => mtime || fs.mtime(file), :max_age => :static
      content_type(MimeMagic.by_extension(File.extname(file)) || 'application/octet-stream')
      response['Content-Length'] ||= fs.size(file).to_s
      halt fs.open(file)
    else
      pass
    end
  end
end

def setup
  fs = DirectoryFS.new(Wiki::Config.tmp_path)
  AssetManager.scripts.each do |type, s|
    name = 'assets.' + type
    File.open(File.join(Wiki::Config.tmp_path, name), 'w') {|out| out << s.sort_by(&:first).map(&:last).join("\n") }
    AssetManager.assets[name] = [fs, name, s.map {|x| x[1] }.max]
  end
  AssetManager.scripts.clear
end
