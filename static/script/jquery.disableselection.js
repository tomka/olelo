// Disable text selection
// Written by Daniel Mendler
jQuery.fn.disableSelection = function() {
    return this.attr('unselectable', 'on')
               .css('MozUserSelect', 'none')
               .bind('selectstart.ui', function() { return false; });
};
