dependencies 'misc/sidebar'
author       'Daniel Mendler'
description  'Tree Viewer'

class Wiki::App

  add_hook(:after_head) do
    '<link rel="stylesheet" href="/sys/treeview/treeview.css" type="text/css"/>' +
      '<script src="/sys/treeview/jquery.treeview.js" type="text/javascript"></script>'
  end

  add_hook(:before_sidebar) do
%Q{
<div id="treeview-tabs">
  <ul>
    <li class="tabs-selected"><a href="#sidebar-menu">#{:menu.t}</a></li>
    <li><a href="#sidebar-treeview">#{:tree.t}</a></li>
  </ul>
</div>
<div id="sidebar-treeview">
  <h1>#{:tree.t}</h1>
  <div id="treeview">#{:loading.t}</div>
</div>
<div id="sidebar-menu">}
  end

  add_hook(:after_sidebar) do
    '</div>'
  end

  public_files 'jquery.treeview.js',
               'expanded.png',
               'collapsed.png',
               'spinner.gif',
	       'treeview.css'

  get '/sys/treeview.json' do
    content_type 'application/json', :charset => 'utf-8'

    resource = Resource.find!(repository, params[:dir], params[:sha])
    cache_control :etag => resource.latest_commit.id, :last_modified => resource.latest_commit.date

    result = '[';
    result << resource.children.map do |child|
      ext = child.page? && child.extension.empty? ? '' : " file-type-#{ext}"
      "[#{child.tree? && !child.children.empty?},'#{child.tree? ? 'tree' : 'page' + ext}','#{resource_path(child)}','#{child.name}']"
    end.join(',')
    result << ']'
  end
end
