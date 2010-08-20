description 'Interwiki support'

def interwiki
  @interwiki ||= YAML.load_file(File.join(Config.config_path, 'interwiki.yml'))
end

INTERWIKI_REGEX = %r{^/?(#{interwiki.keys.join('|')}):(.+)$}

module Olelo::PageHelper
  alias page_path_without_interwiki page_path

  def page_path(page, opts = {})
    if opts[:path] =~ INTERWIKI_REGEX
      absolute_path(opts[:path])
    else
      page_path_without_interwiki(page, opts)
    end
  end
end

Application.get '/:interwiki::page', :interwiki => interwiki.keys.join('|'), :page => '.*' do
  redirect(Plugin.current.interwiki[params[:interwiki]] + params[:page])
end
