// Simple, unobtrusive tab widget
// Written by Daniel Mendler
(function($) {
    $.fn.tabs = function(options) {
	var selected = null,
	    store = options && options.store,
	    links = $("ul:first > li > a[href^='#']", this).each(function() {
	    	        this.tabName = this.href.match(/(#.*)$/)[1];
		    });

	$("ul:first > li > a[href^='#']", this).click(function() {
	    links.each(function() { $(this.tabName).hide(); });
	    links.parent().removeClass('selected');
	    $(this).parent().addClass('selected');
	    $(this.tabName).show();
	    if (store)
		jStorage.set(store, this.tabName);
	    return false;
	});

	if (store) {
	    var name = jStorage.get(store);
	    if (name)
		selected = $("ul:first > li > a[href='" + name + "']", this);
	}
	if (!selected || selected.get().length == 0)
	    selected = $("ul:first > li.selected > a[href^='#']", this);
	selected.click();
    };
})(jQuery);
