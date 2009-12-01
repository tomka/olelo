// Written by Daniel Mendler
(function($) {
    $.styleswitcher = {
	set: function(name) {
	    $('link[rel*=style][title]').each(function() { this.disabled = this.title != name; });
	    $.store.set('style', name);
	},
	toggle: function() {
	    var links = $('link[rel*=style][title]').get();
	    for (var i in links) {
		if (!links[i].disabled) {
		    i = i + 1 < links.length ? i + 1 : 0;
		    $.styleswitcher.set(links[i].title);
		    break;
		}
	    }
	}
    };
    $.fn.styleswitcher = function() {
	var html = 'Themes: <ul class="styleswitcher"><li><a href="#">none</a></li>';
	$('link[rel*=style][title]').each(function() {
	    if (this.title != 'default')
		html += '<li><a href="#">' + this.title + '</a></li>';
	});
	html += '</ul>';
	$(this).html(html);
	$('.styleswitcher li a').click(function() {
	    $.styleswitcher.set($(this).text());
	    return false;
	});
	var style = $.store.get('style');
	if (style)
	    $.styleswitcher.set(style);
    };
})(jQuery);
