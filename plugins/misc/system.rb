author      'Daniel Mendler'
description 'System information'

class Wiki::Application
  get '/system' do
    GC.start
    @plugins = Plugin.plugins.sort_by(&:name)
    @failed_plugins = Plugin.failed.sort
    @disabled_plugins = Plugin.disabled.sort
    @memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    render :system
  end
end
