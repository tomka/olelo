// Simple, unobtrusive tab widget
// Written by Daniel Mendler
(function($) {
    $.fn.tabs = function(options) {
        var store = options && options.store;

        // Find all tabs
	var links = $("ul:first > li > a[href^='#']", this).each(function() {
	    	        this.tabName = this.href.match(/(#.*)$/)[1];
		    });

        // Handle tab clicks
	$("ul:first > li > a[href^='#']", this).click(function() {
	    links.each(function() { $(this.tabName).hide(); });
	    links.parent().removeClass('selected');
	    $(this).parent().addClass('selected');
	    $(this.tabName).show();
	    if (store)
		jStorage.set(store, this.tabName);
	    return false;
	});

        // Get selected tab from store
        var selected = null;
	if (store) {
	    var name = jStorage.get(store);
	    if (name)
		selected = $("ul:first > li > a[href='" + name + "']", this);
	}

        // Get selected tab by class
	if (!selected || selected.get().length == 0) {
	    selected = $("ul:first > li.selected > a[href^='#']", this);
            // Select first tab
            if (selected.get().length == 0)
                selected = $("ul:first > li:first > a[href^='#']", this);
        }
	selected.click();
    };
})(jQuery);
