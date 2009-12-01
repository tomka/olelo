(function($) {
    $.extend($.fn, {
	// Tabs
	tabs: function(options) {
	    var cookie = options && options.cookie;
	    var links = $("ul:first > li > a[href^='#']", this).each(function() {
		this.tabName = this.href.match(/(#.*)$/)[1];
	    });

	    $("ul:first > li > a[href^='#']", this).click(function() {
		links.each(function() { $(this.tabName).hide(); });
		links.parent().removeClass('tabs-selected');
		$(this).parent().addClass('tabs-selected');
		$(this.tabName).show();
		if (cookie)
		    $.cookie(cookie, this.tabName, { expires: 365*100, path: '/' });
		return false;
	    });

	    var selected = null;
	    if (cookie)
		selected = $("ul:first > li > a[href='" + $.cookie(cookie) + "']", this);
	    if (!selected || selected.get().length == 0)
		selected = $("ul:first > li.tabs-selected > a[href^='#']", this);
	    selected.click();
	},
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
	},
	// Date toggler
	dateToggler: function() {
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

	    function toggleDate() {
		var elem = $(this);
		var match = elem.attr('class').match(/seconds_(\d+)/);
		elem.children('.ago').text(timeAgo(match[1]));
		elem.children('.full, .ago').toggle();
	    }

	    this.each(function() {
		var elem = $(this);
		elem.html('<span class="full">' + elem.text() + '</span><span class="ago"></span>')
		elem.children('.ago').hide();
		toggleDate.apply(this);
		elem.click(toggleDate);
	    });
	}
    });
})(jQuery);

$(function() {
    $('.tabs').tabs();

    $('table.sortable').tablesorter({widgets: ['zebra']});

    $('table.history').disableSelection();
    $('table.history td *').css({ cursor: 'move' });
    $('table.history tbody tr').draggable({
	helper: function() {
	    var table = $('<table class="history-draggable"><tbody>' + $(this).html() + '</tbody></table>');
	    var a = $.makeArray(table.find('td'));
	    var b = $.makeArray($(this).find('td'));
	    for (var i = 0; i < a.length; ++i)
		$(a[i]).css({ width: $(b[i]).width() + 'px' });
	    return table;
	}
    }).droppable({
	hoverClass: 'history-droppable-hover',
	drop: function(event, ui) {
	    var to = this.id;
	    var from = ui.draggable.attr('id');
	    if (to != from)
		location.href = '/diff?from=' + from + '&to=' + to;
	}
    });

    $('.zebra tr:even').addClass('even');
    $('.zebra tr:odd').addClass('odd');

    $('input.clear').focus(function() {
	if (this.value == this.defaultValue)
	    this.value = '';
    }).blur(function() {
	if (this.value == '')
	    this.value = this.defaultValue;
    });

    $('.date').dateToggler();
    $('label, #menu, .tabs > ul').disableSelection();
    $('#upload-file').change(function() {
	var elem = $('#upload-path');
	if (elem.size() == 1) {
	    var val = elem.val();
	    if (val == '') {
		elem.val(this.value);
	    } else if (val.match(/^(.*\/)?new page$/)) {
		val = val.replace(/new page$/, '') + this.value;
		elem.val(val);
	    }
	}
    });

    $('*[accesskey]').underlineAccessKey();

    $('#themes').styleswitcher();
});
