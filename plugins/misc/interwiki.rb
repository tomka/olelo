description 'Interwiki support'

def interwiki
  @interwiki ||= YAML.load_file(File.join(Config.config_path, 'interwiki.yml'))
end

Application.get '/:interwiki::page', :interwiki => interwiki.keys.join('|'), :page => '.*' do
  redirect(Plugin.current.interwiki[params[:interwiki]] + params[:page])
end
