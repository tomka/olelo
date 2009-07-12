class Wiki::App

TREEVIEW_HEAD = %q{
%link{:rel=>'stylesheet', :href=>'/sys/treeview.css', :type=>'text/css'}
%script{:src=>'/sys/treeview/jquery.cookie.js', :type=>'text/javascript'}
%script{:src=>'/sys/treeview/jquery.treeview.js', :type=>'text/javascript'}
%script{:src=>'/sys/treeview/jquery.treeview.async.js', :type=>'text/javascript'}
:javascript
  $(document).ready(function() {
    $('#treeview').treeview({ url: '/sys/treeview.json', persist: 'cookie' });
    $('#treeview-tabs').tabs();
  });
}

TREEVIEW_SIDEBAR = %q{
#treeview-tabs
  %ul
    %li.tabs-selected
      %a{:href=>'#sidebar-menu'}= :menu.t
    %li
      %a{:href=>'#sidebar-treeview'}= :tree.t
#sidebar-treeview
  %h1 Tree
  %ul#treeview
}

  add_hook(:after_head) do
    haml TREEVIEW_HEAD, :layout => false
  end

  add_hook(:before_sidebar) do
    haml TREEVIEW_SIDEBAR, :layout => false
  end

  public_files 'jquery.cookie.js',
               'jquery.treeview.js',
               'jquery.treeview.async.js',
               'tree_open.png',
               'tree_closed.png'

  get '/sys/treeview.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :treeview
  end

  get '/sys/treeview.json' do
    sleep 1
    params[:root] ||= 'source'
    content_type 'application/json', :charset => 'utf-8'

    params[:root] = '/' if params[:root] == 'source'
    resource = Resource.find!(@repo, params[:root])
    cache_control :etag => resource.latest_commit.sha, :last_modified => resource.latest_commit.date
    '[' + resource.children.map do |child|
      %Q{{'text':'#{tree_image child}<a href="#{resource_path child}">#{child.pretty_name}</a>',
'id':'#{child.path.urlpath}','hasChildren':#{child.tree? && !child.children.empty?},'classes':'#{child.tree? ? 'tree' : 'page'}'}}
    end.join(',') + ']'
  end
end
