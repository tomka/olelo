(function($) {
    $.extend($.fn, {
	treeView: function(options) {
	    if (!options) options = {};
	    if (!options.root) options.root = '/';
	    if (!options.url) options.url = '/_/treeview.json';
            if (!options.delay) options.delay = 1000;

	    function openTree(element, path) {
		if (element.children('ul').length != 0) {
		    element.children('ul').show();
		    return;
		}
		element.addClass('wait');

                function createChild(data) {
                    var path = data[3],
                        child = $('<li name="'+data[4]+'" tree="'+ (data[0] ? 1 : 0) + '"><div class="'+
                                  (data[1] ? 'hitarea collapsed' : 'placeholder')+
                                  '"><div class="arrow"/><div class="'+data[2]+'"/></div><a href="'+path+'">'+data[4]+'</a></li>'),
                        hitarea = child.children('.hitarea');
                    hitarea.click(function() {
                        if (hitarea.hasClass('collapsed')) {
                            openTree(child, path);
                            hitarea.removeClass('collapsed').addClass('expanded');
                        } else {
                            child.children('ul').hide();
                            hitarea.removeClass('expanded').addClass('collapsed');
                        }
                        setExpanded(path, hitarea.hasClass('expanded'));
                        return false;
                    });
                    if (isExpanded(path)) {
                        openTree(child, path);
                        hitarea.removeClass('collapsed').addClass('expanded');
                    }
                    return child;
                }

		function dataReceived(data) {
                    var ul = $('<ul></ul>');
		    $.each(data, function(i, child) { ul.append(createChild(child)); });
		    if (path == options.root)
			element.empty();
		    element.children('ul').remove();
		    element.removeClass('wait').append(ul);
		}

		function dataUpdated(data) {
                    var exists = {}, list = [];
		    $.each(data, function(i, child) {
                        exists[child[4]] = child;
                    });
		    $('> ul > li', element).each(function() {
                        var li = $(this), name = li.attr('name');
			if (!exists[name])
                            li.remove();
                        else
                            delete exists[name];
                        list.push($(this));
		    });
		    $.each(exists, function(name, child) {
                        var inserted = false;
                        $.each(list, function(i, other) {
			    if ((child[0] && !other.attr('tree')) || (name < other.attr('name') && child[0] == other.attr('tree'))) {
                                inserted = true;
                                other.before(createChild(child));
                                return false;
                            }
                        });
                        if (!inserted)
                            element.children('ul').append(createChild(child));
                    });
		}

		if (options.counterStore) {
		    var counter = $.store.get(options.counterStore, 0);
		    $.ajax({url: options.url, data: { dir: path, _: counter }, dataType: 'json', type: 'GET', success: dataReceived});
		    setTimeout(function() {
		        $.ajax({url: options.url, data: { dir: path, _: counter + 1 }, dataType: 'json', type: 'GET',
		    	    success: function(data) {
				$.store.set(options.counterStore, counter + 1);
			        dataUpdated(data);
			    }
		        });
                    }, options.delay);
		} else {
		    $.ajax({url: options.url, data: { dir: path }, dataType: 'json', type: 'GET', success: dataReceived});
		}
	    }

	    function isExpanded(path) {
		return options.stateStore && $.inArray(path, $.store.get(options.stateStore, [])) >= 0;
	    }

	    function setExpanded(path, expanded) {
		if (options.stateStore) {
		    var state = $.store.get(options.stateStore, []);
		    if (!expanded)
			state = $.grep(state, function(n, i) { return n != path; });
		    else if ($.inArray(path, state) < 0)
			state.push(path);
		    $.store.set(options.stateStore, state);
		}
	    }

	    this.each(function() {
		openTree($(this), options.root);
	    });
	}
    });
})(jQuery);
