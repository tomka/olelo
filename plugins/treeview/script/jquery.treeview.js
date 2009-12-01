(function($) {
    $.extend($.fn, {
	treeView: function(options) {
	    if (!options) options = {};
	    if (!options.root) options.root = '/';
	    if (!options.url) options.url = '/sys/treeview.json';

	    function openTree(element, path) {
		if (element.children('ul').length != 0) {
		    element.children('ul').show();
		    return;
		}
		element.addClass('wait');
		$.ajax({url: options.url, data: { dir: path }, dataType: 'json', type: 'GET', success: function(data) {
		    var html = '<ul>';
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

	    function readState() {
		var cookie = $.cookie(options.cookie);
		return cookie ? cookie.split(',') : [];
	    }

	    function isExpanded(path) {
		return options.cookie && $.inArray(path, readState()) >= 0;
	    }

	    function setExpanded(path, expanded) {
		if (options.cookie) {
		    var state = readState();
		    if (!expanded)
			state = $.grep(state, function(n, i) { return n != path; });
		    else if ($.inArray(path, state) < 0)
			state.push(path);
		    $.cookie(options.cookie, state.join(','), { expires: 365*100, path: '/' });
		}
	    }

	    function bindTree(element) {
		element.find('li > .hitarea').click(function() {
		    var hitarea = $(this);
		    var parent = hitarea.parent();
		    var path = parent.children('a').attr('href');
		    if (hitarea.hasClass('collapsed')) {
			openTree(parent, path);
			hitarea.removeClass('collapsed').addClass('expanded');
		    } else {
			parent.children('ul').hide();
			hitarea.removeClass('expanded').addClass('collapsed');
		    }
		    setExpanded(path, hitarea.hasClass('expanded'));
		    return false;
		}).each(function() {
		    var hitarea = $(this);
		    var parent = hitarea.parent();
		    var path = parent.children('a').attr('href');
		    if (isExpanded(path)) {
			openTree(parent, path);
			hitarea.removeClass('collapsed').addClass('expanded');
		    }
		});
	    }

	    this.each(function() {
		openTree($(this), options.root);
	    });
	}
    });
})(jQuery);
