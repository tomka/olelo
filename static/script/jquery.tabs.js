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
	    links.parent().removeClass('tabs-selected');
	    $(this).parent().addClass('tabs-selected');
	    $(this.tabName).show();
	    if (store)
		$.store.set(store, this.tabName);
	    return false;
	});

	if (store) {
	    var name = $.store.get(store);
	    if (name)
		selected = $("ul:first > li > a[href='" + name + "']", this);
	}
	if (!selected || selected.get().length == 0)
	    selected = $("ul:first > li.tabs-selected > a[href^='#']", this);
	selected.click();
    };
})(jQuery);
