// Add treeview translations
$.translations({
    en: {
      menu: 'Menu',
      tree: 'Tree'
    },
    de: {
      menu: 'Menü',
      tree: 'Baumansicht'
    }
});

// Start tree view
(function() {
    var sidebar = $('#sidebar');
    sidebar.wrapInner('<div id="sidebar-menu"/>').prepend(
            '<div id="treeview-tabs"><ul><li class="tabs-selected"><a href="#sidebar-menu">' + $.t('menu') +
            '</a></li><li><a href="#sidebar-treeview">' + $.t('tree') + '</a></li></ul></div>' +
            '<div id="sidebar-treeview"><h1>' + $.t('tree') +
            '</h1><div id="treeview"/></div>');
    $('#treeview-tabs').tabs({store: 'treeview-tabs'});
    $('#treeview').treeView({stateStore: 'treeview-state', cacheStore: 'treeview-cache', ajax: function(path, success, error) {
        $.ajax({url: path, data: { output: 'treeview.json' }, success: success, error: error});
    }});
})();
