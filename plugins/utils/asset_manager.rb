description 'Asset manager'

module Olelo::AssetManager
  @assets = {}
  @scripts = {}

  class << self
    attr_reader :assets, :scripts

    def register_assets(*files)
      base = File.dirname(Plugin.current(1).name)
      fs.glob(*files) {|fs, file| assets[base/file] = [fs, file] }
    end

    def register_scripts(*files)
      options = files.last.is_a?(Hash) ? files.pop : {}
      priority = options[:priority] || 99
      fs.glob(*files) do |fs, file|
        type = %w(js css).find {|ext| file.ends_with? ext }
        raise 'Invalid script type' if !type
        (scripts[type] ||= []) << [priority, fs.mtime(file), fs.read(file)]
      end
    end

    private

    def fs
      file = Plugin.current(1).file
      UnionFS.new(Config.production? ? CacheInlineFS.new(file) : InlineFS.new(file), DirectoryFS.new(File.dirname(file)))
    end
  end
end

class Olelo::Application
  hook :layout, 1 do |name, doc|
    asset = AssetManager.assets['assets.css']
    if asset
      path = absolute_path "_/assets/assets.css?#{asset[2].to_i}"
      doc.css('head').first << %{<link rel="stylesheet" href="#{escape_html path}" type="text/css"/>}
    end
    asset = AssetManager.assets['assets.js']
    if asset
      path = absolute_path "_/assets/assets.js?#{asset[2].to_i}"
      doc.css('body').first << %{<script src="#{escape_html path}" type="text/javascript"/>}
    end
  end

  get "/_/assets/:name", :name => '.*' do
    if asset = AssetManager.assets[params[:name]]
      fs, file, mtime = asset
      cache_control :last_modified => mtime || fs.mtime(file), :max_age => :static
      response['Content-Type'] = (MimeMagic.by_extension(File.extname(file)) || 'application/octet-stream').to_s
      response['Content-Length'] ||= fs.size(file).to_s
      halt fs.open(file)
    else
      pass
    end
  end
end

def setup
  fs = DirectoryFS.new(Olelo::Config.tmp_path)
  AssetManager.scripts.each do |type, s|
    name = 'assets.' + type
    File.open(File.join(Olelo::Config.tmp_path, name), 'w') {|out| out << s.sort_by(&:first).map(&:last).join("\n") }
    AssetManager.assets[name] = [fs, name, s.map {|x| x[1] }.max]
  end
  AssetManager.scripts.clear
end
