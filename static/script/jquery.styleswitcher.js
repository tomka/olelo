// Styleswitcher from http://www.kelvinluck.com/assets/jquery/styleswitch/toggle.html
// Adapted by Daniel Mendler
(function($) {
    $.translations({
         en: {
            themes:   'Themes',
            no_theme: 'No theme'
         },
         de: {
            themes:   'Seitenstile',
            no_theme: 'Kein Seitenstil'
         }
    });
    $.styleswitcher = {
	set: function(name) {
	    $('link[rel*=style][title]').each(function() { this.disabled = this.title != name; });
	    $.jStorage.set('style', name);
	},
	toggle: function() {
	    var links = $('link[rel*=style][title]').get(), i;
	    for (i in links) {
		if (!links[i].disabled) {
		    i = i + 1 < links.length ? i + 1 : 0;
		    $.styleswitcher.set(links[i].title);
		    break;
		}
	    }
	}
    };
    $.fn.styleswitcher = function() {
	var html = $.t('themes') + ': <ul class="styleswitcher"><li><a href="#">' + $.t('no_theme') + '</a></li>', style;
	$('link[rel*=style][title]').each(function() {
	    if (this.title != 'default')
		html += '<li><a href="#">' + this.title + '</a></li>';
	});
	html += '</ul>';
	this.html(html);
	$('.styleswitcher > li > a').click(function() {
	    $.styleswitcher.set($(this).text());
	    return false;
	});
	style = $.jStorage.get('style');
	if (style)
	    $.styleswitcher.set(style);
    };
})(jQuery);
