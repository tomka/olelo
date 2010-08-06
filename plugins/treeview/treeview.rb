description  'Tree Viewer'
dependencies 'engine/engine', 'utils/asset_manager'
require      'yajl/json_gem'

AssetManager.register_scripts '*.js', '*.css'
AssetManager.register_assets '*.png', '*.gif'

Engine.create('treeview.json', :cacheable => true, :hidden => true, :accepts => Tree::MIME, :mime => 'application/json; charset=utf-8') do
  def output(context)
    # Format [[is-tree, has-children, classes, path, name], ...]
    # Example: [[1, 1, 'tree', '/a/b', 'b'], ...]
    context.tree.children.map do |child|
      ext = !child.page? || child.extension.empty? ? '' : " file-type-#{child.extension.downcase}"
      [child.tree? ? 1 : 0, child.tree? && !child.children.empty? ? 1 : 0, child.tree? ? 'tree' : 'page' + ext, resource_path(child), child.name]
    end.to_json
  end
end
