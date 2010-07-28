description 'Asset manager'

class Wiki::AssetManager
  def self.assets
    @assets ||= {}
  end

  def self.scripts
    @scripts ||= {}
  end

  def self.register_assets(*files)
    find(files) do |file|
      assets[file[Plugin.dir.length+1..-1]] = [File.mtime(file), file]
    end
  end

  def self.register_scripts(*files)
    find(files) do |file|
      type = %w(js css).find {|ext| file.ends_with? ext }
      raise 'Invalid script type' if !type
      (scripts[type] ||= []) << file
    end
  end

  def self.find(files, &block)
    dir = File.dirname(Plugin.current(2).file)
    files.each do |file|
      Dir[File.join(dir, file)].select {|path| File.file? path }.each(&block)
    end
  end

  def self.setup
    FileUtils.mkdir_p Wiki::Config.cache, :mode => 0755
    file = File.join(Wiki::Config.cache, 'assets.')
    scripts.each do |type, s|
      File.open(file + type, 'w') {|out| s.each {|path| out << File.read(path) } }
      assets['assets.' + type] = [s.map {|path| File.mtime(path) }.max, file + type]
    end
  end
end

class Wiki::Application
  hook :layout do |name, doc|
    doc.css('head').first << '<link rel="stylesheet" href="/_/assets/assets.css" type="text/css"/>' if AssetManager.assets['assets.css']
    doc.css('body').first << '<script src="/_/assets/assets.js" type="text/javascript"/>' if AssetManager.assets['assets.js']
  end

  get "/_/assets/:name", :name => /.*/ do
    if asset = AssetManager.assets[params[:name]]
      cache_control :last_modified => asset[0], :max_age => :static
      send_file asset[1]
    else
      :not_found
    end
  end
end

setup { AssetManager.setup }
