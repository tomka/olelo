author      'Daniel Mendler'
description 'System information'

class Wiki::App
  get '/system' do
    GC.start
    @plugins = Plugin.plugins.sort_by(&:name)
    @disabled_plugins = Array === Config.disabled_plugins ? Config.disabled_plugins : []
    @memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    haml :system
  end
end
