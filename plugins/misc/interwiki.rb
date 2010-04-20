author      'Daniel Mendler'
description 'Interwiki support'

def interwiki
  @interwiki ||= YAML.load_file(File.join(Config.root, 'interwiki.yml'))
end

INTERWIKI_REGEX = %r{^/?(#{interwiki.keys.join('|')}):(.+)$}

module Wiki::PageHelper
  alias resource_path_without_interwiki resource_path

  def resource_path(resource, opts = {})
    if opts[:path] =~ INTERWIKI_REGEX
      opts[:path].urlpath
    else
      resource_path_without_interwiki(resource, opts)
    end
  end
end

Application.get INTERWIKI_REGEX do
  redirect(Plugin.current.interwiki[params[:captures][0]] + params[:captures][1])
end
