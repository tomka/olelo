$(document).ready(function(){
    $('.ui-tabs').tabs();
    $('table.sortable').tablesorter({widgets: ['zebra']});
    $('table.history').tablesorter({
	widgets: ['zebra'],
        headers: { 
            0: { sorter: false }, 
            1: { sorter: 'text' },
	    2: { sorter: 'text' },
	    3: { sorter: 'text' }, // FIXME: Write parser for date
	    4: { sorter: 'text' }
        }
    }); 
});
