class Wiki::App

TREEVIEW_HEAD = %q{
%link{:rel=>'stylesheet', :href=>'/sys/treeview.css', :type=>'text/css'}
%script{:src=>'/sys/treeview/jquery.treeview.js', :type=>'text/javascript'}}

TREEVIEW_SIDEBAR = %q{
#treeview-tabs
  %ul
    %li.tabs-selected
      %a{:href=>'#sidebar-menu'}= :menu.t
    %li
      %a{:href=>'#sidebar-treeview'}= :tree.t
#sidebar-treeview
  %h1 Tree
  #treeview
}

  add_hook(:after_head) do
    haml TREEVIEW_HEAD, :layout => false
  end

  add_hook(:before_sidebar) do
    haml TREEVIEW_SIDEBAR, :layout => false
  end

  public_files 'jquery.treeview.js',
               'tree_open.png',
               'expanded.png',
               'collapsed.png',
               'spinner.gif'

  get '/sys/treeview.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :treeview
  end

  get '/sys/treeview.json' do
    content_type 'application/json', :charset => 'utf-8'

    resource = Resource.find!(@repo, params[:dir])
    cache_control :etag => resource.latest_commit.sha, :last_modified => resource.latest_commit.date

    result = '[';
    result << resource.children.map do |child|
      ext = child.mime.extensions.first
      ext = ext ? " ext_#{ext}" : ''
      "[#{child.tree? && !child.children.empty?},'#{child.tree? ? 'tree' : 'page' + ext}','#{resource_path child}','#{child.pretty_name}']"
    end.join(',')
    result << ']'
  end
end
