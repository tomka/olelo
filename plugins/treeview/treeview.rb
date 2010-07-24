author       'Daniel Mendler'
description  'Tree Viewer'
dependencies 'engine/engine'
require      'json'

Engine.create(:treeview_json, :priority => 999, :layout => false, :cacheable => true, :hidden => true) do
  def accepts?(resource); resource.tree?; end
  def mime(resource); 'application/json; charset=utf-8'; end
  def output(context)
    # Format [[is-tree, has-children, classes, path, name], ...]
    # Example: [[1, 1, 'tree', '/a/b', 'b'], ...]
    context.tree.children.map do |child|
      ext = !child.page? || child.extension.empty? ? '' : " file-type-#{child.extension.downcase}"
      [child.tree? ? 1 : 0, child.tree? && !child.children.empty? ? 1 : 0, child.tree? ? 'tree' : 'page' + ext, resource_path(child), child.name]
    end.to_json
  end
end

class Wiki::Application
  assets 'script.js', '*.png', 'spinner.gif', 'treeview.css'

  hook :layout do |name, doc|
    doc.css('head').first << '<link rel="stylesheet" href="/_/treeview/treeview.css" type="text/css"/>'
    doc.css('body').first << '<script src="/_/treeview/script.js" type="text/javascript"/>'
  end
end
