author      'Daniel Mendler'
description 'System information'

class Wiki::App
  get '/sysinfo' do
    GC.start
    @plugins = Plugin.plugins.values.sort_by {|a| a.name }
    @disabled_plugins = Array === Config.disabled_plugins ? Config.disabled_plugins : []
    @memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    haml :sysinfo
  end
end
