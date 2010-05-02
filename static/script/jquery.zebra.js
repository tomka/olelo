// Zebra tables
// Written by Daniel Mendler
jQuery.fn.zebra = function() {
    $('tr:even', this).addClass('even');
    $('tr:odd', this).addClass('odd');
};
