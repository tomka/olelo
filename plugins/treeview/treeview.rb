author       'Daniel Mendler'
description  'Tree Viewer'
dependencies 'misc/sidebar'

class Wiki::Application
  after :style do
    '<link rel="stylesheet" href="/_/treeview/treeview.css" type="text/css"/>'
  end

  after :script do
    '<script src="/_/treeview/script.js" type="text/javascript"></script>'
  end

  assets 'script.js',
         '*.png',
         'spinner.gif',
	 'treeview.css'

  get '/_/treeview.json' do
    begin
      require 'json'

      content_type 'application/json', :charset => 'utf-8'
      tree = Tree.find!(params[:dir], params[:version])
      cache_control :etag => tree.version, :last_modified => tree.version.date

      tree.children.map do |child|
        ext = !child.page? || child.extension.empty? ? '' : " file-type-#{child.extension.downcase}"
        [child.tree? ? 1 : 0, child.tree? && !child.children.empty? ? 1 : 0, child.tree? ? 'tree' : 'page' + ext, resource_path(child), child.name]
      end.to_json
    rescue => ex
      logger.error ex
      [Rack::Utils.status_code(ex.try(:status) || :internal_server_error), ['[]']]
    end
  end
end
