(function($) {
    $.extend($.fn, {
	// Underline text
	underlineText: function(str) {
	    this.each(function() {
		if ($(this).children().get().length == 0) {
		    var text = $(this).text();
		    var i = text.toLowerCase().indexOf(str.toLowerCase());
		    if (i >= 0)
			$(this).html(text.substr(0, i) + '<span style="text-decoration: underline">' +
					    text.substr(i, str.length) + '</span>' + text.substr(i+str.length));
		} else {
		    $(this).children().underlineText(str);
		}
	    });
	},
	// Underline access key
	underlineAccessKey: function() {
	    this.each(function() {
		var key = $(this).attr('accesskey');
		if (key)
		    $(this).underlineText(key);
	    });
	}
    });
})(jQuery);
