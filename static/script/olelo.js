// Olelo bootstrap
// Written by Daniel Mendler
(function() {
    $('#themes').styleswitcher();
    $('.tabs').tabs();
    $('#history-table').historyTable();
    $('.zebra, #history-table, #tree-table').zebra();
    $('.date').dateToggler();
    $('input.placeholder').placeholder();
    $('label, #menu, .tabs > ul, .pagination').disableSelection();

    $('#upload-path').each(function() {
        var elem = this;
        var old = elem.value;
        var base = elem.value;
        if (base.length == 0 || base.match(/\/$/)) {
            $('#upload-file').change(function() {
                if (elem.value == old) {
                    elem.value = base + this.value;
                    old = elem.value;
                }
            });
        }
    });

    $('*[accesskey]').underlineAccessKey();

    $('.pagination a:not(.current)').pagination('#content');
    $('#content').bind('pageLoaded', function() {
        $('.zebra, #history-table, #tree-table', this).zebra();
	$('.date', this).dateToggler();
    });
})();
