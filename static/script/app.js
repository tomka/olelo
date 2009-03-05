// From http://nullstyle.com/2007/06/02/caching-time_ago_in_words/

function timeAgo(from) {
    return timeDistance(new Date().getTime(), new Date(from * 1000)) + ' ago';
}

function timeDistance(to, from) {
    n = Math.floor((to  - from) / 60000)
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

function toggleTime() {
    elem = $(this);
    match = elem.attr('class').match(/seconds_(\d+)/);
    if (elem.attr('oldtext')) {
	elem.text(elem.attr('oldtext'));
	elem.removeAttr('oldtext');
    } else {
	elem.attr('oldtext', elem.text());
	elem.text(timeAgo(match[1]));
    }
}

function confirmSubmit() {
    return confirm('Are you sure?');
}

function updateUploadPath() {
    elem = $('#upload-path');
    if (elem.size() == 1) {
	val = elem.val();
	if (val.match(/^(.*\/)?new page$/)) {
	    val = val.replace(/new page$/, '') + this.value;
	    elem.val(val);
	}
    }
}

$(document).ready(function(){
    $('.ui-tabs').tabs();
    $('table.sortable').tablesorter({widgets: ['zebra']});
    $('table.history').tablesorter({
	widgets: ['zebra'],
        headers: {
            0: { sorter: false },
            1: { sorter: false },
            2: { sorter: 'text' },
	    3: { sorter: 'text' },
	    4: { sorter: 'text' }, // FIXME: Write parser for date
	    5: { sorter: 'text' },
            6: { sorter: false }
        }
    });

    $('input.clear').focus(function() {
	if (this.value == this.defaultValue)
	    this.value = '';
    }).blur(function() {
	if (this.value == '')
	    this.value = this.defaultValue;
    });

    $('.date').click(toggleTime);
    $('.date').each(toggleTime);
    $('.confirm').click(confirmSubmit);
    $('#upload-file').change(updateUploadPath);
});
