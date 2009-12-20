jQuery.fn.disableSelection = function() {
    return this.attr('unselectable', 'on')
               .css('MozUserSelect', 'none')
               .bind('selectstart.ui', function() { return false; });
};

jQuery.fn.historyTable = function() {
    $(this).disableSelection();
    var rows = $('tbody tr', this);
    rows.mousedown(function(event) {
        event.preventDefault();

	var from = $(this),
            offset = from.offset(),
            to = null;
	    fromText = $('td:first-child a:first-child', from).text(),
	    fromDate = $('td:nth-child(3)', from).text(),
	    draggable = null;

	function stop() {
	    if (draggable)
                draggable.remove();
	    $(document).unbind('mouseup.history keypress.history');
	    rows.unbind('mouseover.history mousemove.history');
	}

	$(document).bind('mouseup.history', function() {
	    stop();
	    if (to) {
	        var toSha = to.attr('id').substr(7),
	            fromSha = from.attr('id').substr(7),
                    path = location.pathname;
	        if (toSha != fromSha) {
		    path = path.substr(0, path.length - 7);
	            location.href = path + 'diff?from=' + fromSha + '&to=' + toSha;
		}
            }
            return true;
	}).bind('keypress.history', function(event) {
	    stop();
	    return true;
	});

	rows.bind('mousemove.history', function(moveEvent) {
            var distance = Math.abs(event.pageX - moveEvent.pageX) + Math.abs(event.pageY - moveEvent.pageY);
            if (distance > 5) {
                draggable = $('<div class="history-draggable">' + fromText + ' (' + fromDate + ')</div>').css({
                    width: from.width() + 'px',
                    height: from.height() + 'px',
                    position: 'absolute',
                    display: 'block',
                    zIndex: 1000,
                    cursor: 'move',
                    top: Math.round(offset.top) + 'px',
                    left: Math.round(offset.left) + 'px'
		}).appendTo('body');
		rows.unbind('mousemove.history');
	    }
            return true;
	}).bind('mouseover.history', function() {
            if (draggable) {
                to = $(this);
		var toText = $('td:first-child a:first-child', to).text(),
		    toDate = $('td:nth-child(3)', to).text(),
		    offset = to.offset();
                draggable.css({
	            top: Math.round(offset.top) + 'px',
		    left: Math.round(offset.left) + 'px'
	        }).html(fromText + ' (' + fromDate + ') &#8594; ' + toText + ' (' + toDate + ')');
	    }
            return true;
	});

	$(document).mouseup(mouseup);
	return false;
    });
};


// Wiki bootstrap
// Written by Daniel Mendler
$(function() {
    $('.tabs').tabs();

    $('table.sortable').tablesorter({widgets: ['zebra']});

    $('table.history').historyTable();

    $('.zebra tr:even').addClass('even');
    $('.zebra tr:odd').addClass('odd');

    $('input.placeholder').placeholder();

    $('.date').dateToggler();
    $('label, #menu, .tabs > ul').disableSelection();
    $('#upload-file').change(function() {
	var elem = $('#upload-path'), val;
	if (elem.size() == 1) {
	    val = elem.val();
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
