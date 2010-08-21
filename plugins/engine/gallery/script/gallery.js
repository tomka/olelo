(function() {
    function initGallery() {
        $('.gallery a').fancybox({
            'transitionIn'  : 'fade',
            'transitionOut' : 'fade',
            'titlePosition' : 'over',
            'titleFormat'   : function(title, currentArray, currentIndex, currentOpts) {
                return '<span id="fancybox-title-over">' + (currentIndex + 1) + ' / ' + currentArray.length + ' ' + (title ? title : '') + '</span>';
        }});
    }

    $('#content').bind('pageLoaded', initGallery);
    initGallery();
})();
