$(function() {
    if ($.browser.mozilla || $.browser.safari) {
	sidebar = $('#sidebar');
	sidebar.html('<div id="treeview-tabs"><ul><li class="tabs-selected"><a href="#sidebar-menu">Menu</a></li><li><a href="#sidebar-treeview">Tree</a></li></ul></div>' +
		     '<div id="sidebar-treeview"><h1>Tree</h1><div id="treeview"></div></div><div id="sidebar-menu">' + sidebar.html() + '</div>');
	$('#treeview-tabs').tabs({store: 'treeview-tabs'});
	$('#treeview').treeView({store: 'treeview'});
    }
});
