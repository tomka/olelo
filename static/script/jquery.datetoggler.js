// Written by Daniel Mendler
(function($) {
    $.fn.dateToggler = function() {
	function timeDistance(to, from) {
	    var n = Math.floor((to  - from) / 60000)
	    if (n == 0) return 'less than a minute';
	    if (n == 1) return 'a minute';
	    if (n < 45) return n + ' minutes';
	    if (n < 90) return ' about 1 hour';
	    if (n < 1440) return 'about ' + Math.round(n / 60) + ' hours';
	    if (n < 2880) return '1 day';
	    if (n < 43200) return Math.round(n / 1440) + ' days';
	    if (n < 86400) return 'about 1 month';
	    if (n < 525960) return Math.round(n / 43200) + ' months';
	    if (n < 1051920) return 'about 1 year';
	    return 'over ' + Math.round(n / 525960) + ' years';
	}

	function timeAgo(from) {
	    return timeDistance(new Date().getTime(), new Date(from * 1000)) + ' ago';
	}

	this.each(function() {
	    var elem = $(this);
	    var text = elem.text();
	    var match = elem.attr('class').match(/epoch-(\d+)/);
	    if (match)
	        elem.click(function() { elem.html(elem.text() == text ? timeAgo(match[1]) : text); }).click();
	});
    };
})(jQuery);
