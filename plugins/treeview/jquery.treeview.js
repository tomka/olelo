(function($) {
    $.extend($.fn, {
	treeView: function(options) {
	    if(!options) options = {};
	    if(!options.root) options.root = '/';
	    if(!options.url) options.url = '/sys/treeview.json';

	    function openTree(element, path) {
		if (element.children('ul').length != 0) {
		    element.children('ul').show();
		    return;
		}
		element.addClass('wait');
		$.ajax({url: options.url, data: { dir: path }, dataType: 'json', type: 'GET', success: function(data) {
		    html = '<ul>';
		    $.each(data, function(i, child) {
			html += '<li><div class="'+(child[0] ? 'hitarea collapsed' : 'placeholder')+'"><div class="arrow"/><div class="'+
			    child[1]+'"/></div><a href="'+child[2]+'">'+child[3]+'</a></li>';
		    });
		    html += '</ul>';
		    if (path == options.root)
			element.empty();
		    element.removeClass('wait').append(html);
		    bindTree(element);
		}});
	    }

	    function bindTree(element) {
		element.find('li > .hitarea').click(function() {
		    hitarea = $(this);
		    parent = hitarea.parent();
		    link = parent.children('a');
		    if (hitarea.hasClass('collapsed')) {
			openTree(parent, link.attr('href'));
			hitarea.removeClass('collapsed').addClass('expanded');
		    } else {
			parent.children('ul').hide();
			hitarea.removeClass('expanded').addClass('collapsed');
		    }
		    return false;
		});
	    }

	    this.each(function() {
		openTree($(this), options.root);
	    });
	}
    });
})(jQuery);

$(document).ready(function() {
    $('#treeview-tabs').tabs();
    $('#treeview').treeView();
});
